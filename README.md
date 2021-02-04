![RemoteRecord: Ready-made remote resource structures.](doc/header.svg)

---

![Remote Record](https://github.com/raisedevs/remote_record/workflows/Remote%20Record/badge.svg)
[![Gem Version](https://badge.fury.io/rb/remote_record.svg)](https://badge.fury.io/rb/remote_record)

Every API speaks a different language. Maybe it's REST, maybe it's SOAP, maybe
it's GraphQL. Maybe it's got its own Ruby client, or maybe you need to roll your
own. But what if you could just pretend it existed in your database?

RemoteRecord provides a consistent ActiveRecord inspired interface for all of
your application's APIs. Store remote resources by ID, and RemoteRecord will
auto-populate instances of your ActiveRecord model with their attributes from
the API. Whether you're dealing with a user on GitHub, a track on Spotify, a
place on Google Maps, or a resource on your internal infrastructure, you can use
RemoteRecord to wrap fetching it.

## Setup

### Jargon

**Remote resource** - the resource on the external API that you're trying to
reach. In this example, we're trying to fetch a GitHub user.

**Reference** - your record that points at the remote resource using its ID. In
this example, these are `GitHub::UserReference`s.

**Remote record class** - a class that defines the behavior used to fetch the
remote resource. In this example, it's `RemoteRecord::GitHub::User`.

### Creating a remote record class

A standard RemoteRecord class looks like this. It should have a `get` method,
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

      private

      def client
        Octokit::Client.new(access_token: authorization)
      end
    end
  end
end
```

### Creating a remote reference

To start using your remote record class, `include RemoteRecord` into your reference. Now, whenever
you initialize an instance of your class, it'll be fetched.

Calling `remote_record` in addition to this lets you set some options:

| Key           | Default                  | Purpose                                                                                                                                                                            |
|--------------:|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| klass         | Inferred from class name | The Remote record class to use for fetching attributes                                                                                                                             |
| id_field      | `:remote_resource_id`    | The field on the reference that contains the remote resource ID                                                                                                                    |
| authorization | `''`                     | An object that can be used by the remote record class to authorize a request. This can be a value, or a proc that returns a value that can be used within the remote record class. |
| memoize       | true                     | Whether reference instances should memoize the response that populates them                                                                                                        |
| transform     | []                       | Whether the response should be put through a transformer (under RemoteRecord::Transformers). Currently, only `[:snake_case]` is available.                                         |

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

If your API doesn't require authentication at all, you don't even need to
configure it. So at its best, RemoteRecord can be as lightweight as:

```ruby
class JsonPlaceholderAPIReference < ApplicationRecord
  include RemoteRecord
  # Falls back to the defaults, so it's equivalent to then calling:
  # remote_record do |c|
    # c.authorization proc { }
    # c.id_field :remote_resource_id
    # c.klass RemoteRecord::JsonPlaceholderAPI, # Inferred from module and class name
    # c.memoize true
    # c.transform []
  # end
end
```

## Usage

Now you've got everything lined up to start using your remote reference.

Whenever a `GitHub::UserReference` is initialized, e.g. by calling:

```ruby
user.github_user_references.first
```

...it'll be populated with the GitHub user's data. You can call methods that
return attributes on the user, like `#login` or `#html_url`.

By default, this'll only make a request on initialize. For services that manage
caching by way of expiry or ETags, I recommend using `faraday-http-cache` for
your clients and setting `memoize` to `false`. Remote Record will eventually
gain support for caching.

### `remote_all` and `remote_where`

If you're able to fetch multiple records at once from the API, implement the
`self.all` method on your remote record class. This should return an array of
hashes that can be used to initialize a set of references.

This can optionally take a block
for authorization - note that it won't use the auth you've configured and that
you'll always have to supply that inline. For example:

```ruby
module RemoteRecord
  module GitHub
    # :nodoc:
    class User < RemoteRecord::Base
      def get
        client.user(remote_resource_id)
      end

      def self.all
        Octokit::Client.new(access_token: yield).users
      end

      private

      def client
        Octokit::Client.new(access_token: authorization)
      end
    end
  end
end
```

Now you can call `remote_all` on remote reference classes that use
`RemoteRecord::GitHub::User`, like this:

```ruby
GitHub::UserReference.remote_all { GITHUB_PERSONAL_ACCESS_TOKEN }
```

`remote_where` works in the same way, but with a parameter:

```ruby
module RemoteRecord
  module GitHub
    # :nodoc:
    class User < RemoteRecord::Base
      def get
        client.user(remote_resource_id)
      end

      def self.all
        Octokit::Client.new(access_token: yield).users
      end

      def self.where(query)
        Octokit::Client.new(access_token: yield).search_users(query)
      end

      private

      def client
        Octokit::Client.new(access_token: authorization)
      end
    end
  end
end
```

Now you can call `remote_where` on remote reference classes that use
`RemoteRecord::GitHub::User`, like this:

```ruby
GitHub::UserReference.remote_where('q=tom+repos:%3E42+followers:%3E1000') { GITHUB_PERSONAL_ACCESS_TOKEN }
```

It's recommended that you include something in `self.where` to filter incoming
params. Ideally, you want to expose an interface that's as ActiveRecord-like as
possible, e.g.:

```ruby
GitHub::UserReference.remote_where(q: 'tom', repos: '>42', followers: '>1000') { GITHUB_PERSONAL_ACCESS_TOKEN }
```

### `initial_attrs`

Behind the scenes, `remote_all` initializes references with a set of
`initial_attrs`. You can do the same! If you've already fetched the data for an
object, just pass it to `new` for your reference class under the
`initial_attrs:`  keyword parameter, like this:

```ruby
todo = { id: 1, title: 'Hello world' }
TodoReference.new(remote_resource_id: todo[:id], initial_attrs: todo)
```

### Forcing a fresh request

You might want to force a fresh request in some instances, even if you're using
`memoize`. To do this, call `fresh` on a reference, and it'll be repopulated.

### Skip fetching

You might not want to make a request on initialize sometimes. In this case, pass
`fetching: false` to your query or `new` to make sure the resource isn't
fetched.
