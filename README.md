![Remote Record: Ready-made remote resource structures.](doc/header.svg)

---

![Remote Record](https://github.com/raisedevs/remote_record/workflows/Remote%20Record/badge.svg)
[![Gem Version](https://badge.fury.io/rb/remote_record.svg)](https://badge.fury.io/rb/remote_record)

Every API speaks a different language. Maybe it's REST, maybe it's SOAP, maybe
it's GraphQL. Maybe it's got its own Ruby client, or maybe you need to roll your
own. But what if you could just pretend it existed in your database?

Remote Record provides a consistent Active Record-inspired interface for all of
your application's APIs. Store remote resources by ID, and Remote Record will
let you access objects containing their attributes from the API. Whether you're
dealing with a user on GitHub, a track on Spotify, a place on Google Maps, or a
resource on your internal infrastructure, you can use Remote Record to wrap
fetching it.

## Setup

### Jargon

**Remote resource** - the resource on the external API that you're trying to
reach. In this example, we're trying to fetch a GitHub user.

**Reference** - your record that points at the remote resource using its ID. In
this example, these are `GitHub::UserReference`s.

**Remote record class** - a class that defines the behavior used to fetch the
remote resource. In this example, it's `RemoteRecord::GitHub::User`.

### Creating a remote record class

A standard Remote Record class looks like this. It should have a `get` method,
which returns a hash of data you'd like to query on the user.

`RemoteRecord::Base` exposes private methods for the `remote_resource_id` and
`authorization` that you configure on the remote reference.

```ruby
module RemoteRecord
  module GitHub
    # :nodoc:
    class User < RemoteRecord::Base
      def get
        client.user(remote_resource_id)
      end

      # Implement the Collection class here for fetching multiple records.

      private

      def client
        Octokit::Client.new(access_token: authorization)
      end
    end
  end
end
```

These classes can be used in isolation and don't directly depend on Active
Record. You can use them outside of the context of Active Record or Rails:

```ruby
RemoteRecord::GitHub::User.new(1)
=> <RemoteRecord::GitHub::User attrs={}>
```

If you call `fresh` or try to access an attribute, Remote Record will fetch the
resource and put its data in this instance.

### Creating a remote reference

To start using your remote record class, `include RemoteRecord` into your
reference. Now, whenever you initialize an instance of your class, it'll be
fetched.

Calling `remote_record` in addition to this lets you set some options:

| Key           | Default                  | Purpose                                                                                                                                                                            |
|--------------:|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| klass         | Inferred from class name | The Remote record class to use for fetching attributes                                                                                                                             |
| id_field      | `:remote_resource_id`    | The field on the reference that contains the remote resource ID                                                                                                                    |
| authorization | `''`                     | An object that can be used by the remote record class to authorize a request. This can be a value, or a proc that returns a value that can be used within the remote record class. |
| memoize       | true                     | Whether reference instances should memoize the response that populates them                                                                                                        |
| transform     | []                       | Whether the response should be put through a transformer (under `RemoteRecord::Transformers`). See `lib/remote_record/transformers` for options.                                   |

```ruby
module GitHub
  # :nodoc:
  class UserReference < ApplicationRecord
    belongs_to :user
    include RemoteRecord
    remote_record do |c|
      c.authorization { |record| record.user.github_auth_tokens.active.first.token }
      # Defaults:
      # c.id_field :remote_resource_id
      # c.klass RemoteRecord::GitHub::User, # Inferred from module and class name
      # c.memoize true
      # c.transform []
    end
  end
end
```

If the default behavior suits you just fine, you don't even need to
configure it. So at its best, Remote Record can be as lightweight as:

```ruby
class JsonPlaceholderAPIReference < ApplicationRecord
  include RemoteRecord
  remote_record
end
```

## Usage

Now you've got the basics lined up to start using your remote reference.

Whenever you call `remote` on a `GitHub::UserReference`:

```ruby
user.github_user_references.first.remote
```

...you'll be able to use the GitHub user's data on an instance of
`RemoteRecord::GitHub::User`. You can call methods that return attributes on the
user, like `#login` or `#html_url`.

For services that manage caching by way of expiry or ETags, I recommend using
`faraday-http-cache` for your clients and setting `memoize` to `false`. Remote
Record may eventually gain native support for caching your records to the
database.

### `remote` scopes

Remote Record also provides extensions to Active Record scopes. You can call
`remote` on a scope to fetch all the remote resources at once. By default, this
will use a single request per resource, which isn't often optimal.

Implement the `Collection` class under your remote record class to fetch
multiple records from the API in fewer requests. `all` should return an array
of references.

Inheriting from `RemoteRecord::Collection` grants you some convenience methods
you can use to pair the remote resources from the response with your existing
references. Check out the class file under `lib/remote_record` for more details.

```ruby
module RemoteRecord
  module GitHub
    # :nodoc:
    class User < RemoteRecord::Base
      # ...
      class Collection < RemoteRecord::Collection
        def all
          response = client.all_users
          match_remote_resources_by_id(response)
        end

        private

        def client
          Octokit::Client.new
        end
      end
    end
  end
end
```

Now you're ready to fetch all your resources at once:

```ruby
GitHub::UserReference.remote.all
```

`remote.where` works in the same way, but with a parameter:

```ruby
module RemoteRecord
  module GitHub
    # :nodoc:
    class User < RemoteRecord::Base
      # ...
      class Collection < RemoteRecord::Collection
        def all
          response = client.all_users
          match_remote_resources_by_id(response)
        end

        def where(query)
          response = client.search_users(query)
          match_remote_resources_by_id(response)
        end

        private

        def client
          Octokit::Client.new
        end
      end
    end
  end
end
```

Now you can call `remote.where` on remote reference classes that use
`RemoteRecord::GitHub::User`, like this:

```ruby
GitHub::UserReference.remote.where('q=tom+repos:%3E42+followers:%3E1000')
```

*Note that the query we're expecting here comes from the Octokit gem. Your API
client might have a nicer interface.*

It's recommended that you include something in `where` to filter incoming
params. Ideally, you want to expose an interface that's as ActiveRecord-like as
possible, e.g.:

```ruby
GitHub::UserReference.remote_where(q: 'tom', repos: '>42', followers: '>1000')
```

You can use or write a `Transformer` to do this. Check out the
`RemoteRecord::Transformers` module for examples.

### `initial_attrs`

Behind the scenes, `match_remote_resources` sets the remote instance's `attrs`.
You can do the same! If you've already fetched the data for an object, set it
via `attrs`, like this:

```ruby
todo = { id: 1, title: 'Hello world' }
todo_reference = TodoReference.new(remote_resource_id: todo[:id])
todo_reference.remote.attrs = todo
```

### Forcing a fresh request

You might want to force a fresh request in some instances. To do this, call
`fresh` on a reference, and it'll be repopulated.
