# Fripa

A Ruby client for the FreeIPA JSON-RPC API.

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

Fripa offers multiple ways to configure your FreeIPA connection:

### With a block

```ruby
Fripa.configure do |config|
  config.host = 'ipa.example.com'
  config.username = 'admin'
  config.password = 'secret'
  config.verify_ssl = true  # default: true
end
```

### With a hash

```ruby
Fripa.config = {
  host: 'ipa.example.com',
  username: 'admin',
  password: 'secret'
}
```

### With a Configuration instance

```ruby
config = Fripa::Configuration.new(
  host: 'ipa.example.com',
  username: 'admin',
  password: 'secret'
)
Fripa.config = config
```

### Direct attribute assignment

```ruby
Fripa.config.host = 'ipa.example.com'
Fripa.config.username = 'admin'
Fripa.config.password = 'secret'
```

## Usage

### Authentication

After configuring Fripa, authenticate to obtain a session:

```ruby
authenticator = Fripa::Authenticator.new
authenticator.login!

# The session cookie is now stored in the configuration
puts Fripa.config.session_cookie
```

If authentication fails, a `Fripa::AuthenticationError` will be raised:

```ruby
begin
  authenticator.login!
rescue Fripa::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
end
```

### Making API Calls

Use the `Client` class to interact with the FreeIPA API:

```ruby
client = Fripa::Client.new

# Find a user (automatically authenticates if needed)
result = client.call("user_find", ["admin"])
puts result.dig("result", "count")  # Number of users found

# Add a user with options
client.call("user_add", ["newuser"], {
  givenname: "New",
  sn: "User",
  userpassword: "TempPassword123"
})

# Modify a user
client.call("user_mod", ["newuser"], {
  mail: "newuser@example.com"
})

# Delete a user
client.call("user_del", ["newuser"])
```

The client will automatically authenticate using the configured credentials if no session exists.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/fripa. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/fripa/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fripa project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/fripa/blob/main/CODE_OF_CONDUCT.md).
