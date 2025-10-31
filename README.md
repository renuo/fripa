# Fripa

A Ruby client for the FreeIPA JSON-RPC API.

Docs: [FreeIPA JSON-RPC API](https://freeipa.readthedocs.io/en/latest/api/json-rpc.html)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fripa'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install fripa
```

## Configuration

Configure your FreeIPA server settings globally. These settings are shared across all client instances:

### With a block

```ruby
Fripa.configure do |config|
  config.host = 'ipa.example.com'
  config.verify_ssl = true  # default: true
end
```

### With a hash

```ruby
Fripa.config = {
  host: 'ipa.example.com',
  verify_ssl: true
}
```

### With a Configuration instance

```ruby
config = Fripa::Configuration.new(
  host: 'ipa.example.com',
  verify_ssl: true
)
Fripa.config = config
```

### Direct attribute assignment

```ruby
Fripa.config.host = 'ipa.example.com'
Fripa.config.verify_ssl = false
```

## Usage

### Creating a Client

Create a client instance with user credentials. The client authenticates immediately upon creation:

```ruby
client = Fripa::Client.new(
  username: 'your-username',
  password: 'your-password'
)
# Client is now authenticated and ready to use
```

If authentication fails, a `Fripa::AuthenticationError` will be raised immediately:

```ruby
begin
  client = Fripa::Client.new(username: 'admin', password: 'wrong-password')
rescue Fripa::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
end
```

### Making API Calls

#### Using Resource Methods (Recommended)

The gem provides convenient resource methods with parameter validation:

##### Users

```ruby
client = Fripa::Client.new(username: 'admin', password: 'secret')

# Find users
users = client.users.find  # All users
user = client.users.find("admin")  # Find specific user

# Show user details
details = client.users.show("admin")

# Add a user (validates required fields)
client.users.add("newuser",
  givenname: "New",
  sn: "User",
  cn: "New User",
  userpassword: "TempPassword123"
)

# Modify a user
client.users.mod("newuser", mail: "newuser@example.com")

# Change user password
client.users.passwd("newuser", "NewPassword123", "TempPassword123")

# Delete a user
client.users.delete("newuser")
```

##### Groups

```ruby
client = Fripa::Client.new(username: 'admin', password: 'secret')

# Find groups
groups = client.groups.find  # All groups
group = client.groups.find("admins")  # Find specific group

# Show group details
details = client.groups.show("admins")

# Add a group
client.groups.add("developers", description: "Development Team")

# Modify a group
client.groups.mod("developers", description: "Software Development Team")

# Add members to a group
client.groups.add_member("developers", user: ["alice", "bob"])

# Remove members from a group
client.groups.remove_member("developers", user: ["alice"])

# Add member managers (users who can manage group membership)
client.groups.add_member_manager("developers", user: ["manager"])

# Remove member managers
client.groups.remove_member_manager("developers", user: ["manager"])

# Delete a group
client.groups.delete("developers")
```

#### Using Raw API Calls

For API methods without a resource wrapper, use the `call` method directly:

```ruby
client = Fripa::Client.new(username: 'admin', password: 'secret')

# Any FreeIPA JSON-RPC method
result = client.call("user_find", ["admin"], { all: true })
puts result.dig("result", "count")
```

The client will automatically authenticate if no session exists.

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Running Tests

To run the test suite with coverage:

```bash
bin/test
```

This will run all tests and generate a coverage report in `coverage/index.html`. The test suite includes:
- Line coverage tracking
- Branch coverage tracking
- VCR cassettes for testing against FreeIPA sandbox

### Other Development Commands

- `bin/console` - Interactive prompt for experimentation
- `bundle exec rake install` - Install gem onto your local machine
- `bundle exec rubocop` - Run code style checks

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/renuo/fripa. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/renuo/fripa/blob/main/CODE_OF_CONDUCT.md).

For detailed contributing guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fripa project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/renuo/fripa/blob/main/CODE_OF_CONDUCT.md).
