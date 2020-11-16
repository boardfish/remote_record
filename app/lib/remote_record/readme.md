# RemoteRecord

Ready-made remote resource structures.

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
which returns a hash of the data you'd like to query on the user.

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

| Key           | Default                  | Purpose                                                                |
|--------------:|--------------------------|------------------------------------------------------------------------|
| klass         | Inferred from class name | The Remote record class to use for fetching attributes                               |
| id_field      | `:remote_resource_id`    | The field on the reference that contains the remote resource ID        |
| authorization | `proc { }`               | An object that can be used by the remote record class to authorize a request. This can be a value or a proc that returns the value expected by the client      |
| memoize       | true                     | Whether reference instances should memoize the response that populates them |

```ruby
module GitHub
  # :nodoc:
  class UserReference < ApplicationRecord
    belongs_to :user
    include RemoteRecord
    remote_record do |c|
      c.authorization { |reference| reference.user.github_auth_tokens.active.first.token }
      # Defaults:
      # c.id_field :remote_resource_id
      # c.klass RemoteRecord::GitHub::User, # Inferred from module and class name
      # c.memoize true
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

By default, this'll make a request every time you ask for a field. For services
that manage caching by way of expiry or ETags, I recommend using
`faraday-http-cache` for your clients. Remote Record will eventually gain
support for caching.
