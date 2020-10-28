# RemoteRecord

Ready-made remote resource structures.

## Setup

In this example, `User`s have `GitHub::UserReference`s, which point at users on
GitHub's platform.

### Creating a remote record type

A standard RemoteRecord class looks like this. It should have a `get` method,
which returns a hash of the data you'd like to query on the user. Supply
`authorization` and `id` appropriately.

```ruby
module RemoteRecord
  module GitHub
    # :nodoc:
    class User
      include RemoteRecord::Core

      private

      def client
        Octokit::Client.new(access_token: authorization)
      end

      def get
        client.user(id.to_i)
      end
    end
  end
end
```

### Creating a remote reference

To start using your remote record type, create an `ActiveRecord::Base` object
that responds to `remote_resource_id`.

> Note: Make sure you `extend RemoteRecord::DSL` to get access to RemoteRecord's
> methods.

From there, you're three steps away:

1. Specify that this is a link to a `remote_record`.
2. Define `remote_authorization`.
3. Specify the `remote_record_klass` this reference should use.

```ruby
module GitHub
  # :nodoc:
  class UserReference < ApplicationRecord
    belongs_to :user
    validates :remote_resource_id, presence: true
    remote_record

    def remote_authorization
      user.github_auth_tokens.active.first.token
    end

    def remote_record_klass
      RemoteRecord::GitHub::User
    end
  end
end
```

## Usage

Now you've got everything lined up to start using your remote reference.

You can call:

```ruby
user.github_user_reference.remote_record
```

to return a `RemoteRecord::GitHub::User` that's populated with the GitHub user's
data. You can call methods that return attributes on the user, like `#login` or
`#html_url`.

By default, this'll make a request every time you ask for a field. It's the
responsibility of your `client` to handle caching - I recommend using
`faraday-http-cache`.

### Association helpers

If you use `has_(a_)remote :through`, you'll get a shortcut straight to the
remote record through the model. For example, specifying this on the `User`:

```ruby
has_many :github_user_references
has_remote :github_users, through: :github_user_references
```

...will allow you to call this:

```ruby
user.github_users
```

...which equates to `user.github_user_references.remote_records`.

### Authorization override

You might've noticed that the `authorization` method we set earlier uses the
user's active GitHub token. But what if we want to use a single Personal Access
Token in some instances?

Methods that return remote records can all take a parameter. This is used to
override authorization when requesting the associated record. So if we wanted to
use an environment variable sometimes, it's possible to call
`user.github_users(ENV['GITHUB_ACCESS_TOKEN'])` if necessary.
