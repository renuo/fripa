# Fripa

[![Gem Version](https://badge.fury.io/rb/fripa.svg)](https://rubygems.org/gems/fripa)
[![CI](https://github.com/renuo/fripa/actions/workflows/main.yml/badge.svg)](https://github.com/renuo/fripa/actions/workflows/main.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![Docs](https://img.shields.io/badge/docs-rubydoc.info-blue)](https://rubydoc.info/gems/fripa)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE.txt)

A Ruby client for the FreeIPA JSON-RPC API.

Docs: [FreeIPA JSON-RPC API](https://freeipa.readthedocs.io/en/latest/api/json-rpc.html)

## What is FreeIPA
FreeIPA (Free Identity, Policy, Audit) is an open-source identity management system for Linux/Unix environments. It provides centralized authentication, authorization, and account information by integrating LDAP, Kerberos, DNS, and certificate management. Essentially, it helps organizations manage users, groups, and access policies in a secure and unified way.

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
  config.port = 8443         # optional, default: 443 (standard HTTPS port)
  config.scheme = 'https'    # optional, default: 'https' (use 'http' for local development)
  config.verify_ssl = true   # default: true
end
```

### With a hash

```ruby
Fripa.config = {
  host: 'ipa.example.com',
  port: 8443,        # optional
  scheme: 'https',   # optional
  verify_ssl: true
}
```

### With a Configuration instance

```ruby
config = Fripa::Configuration.new(
  host: 'ipa.example.com',
  port: 8443,        # optional
  scheme: 'https',   # optional
  verify_ssl: true
)
Fripa.config = config
```

### Direct attribute assignment

```ruby
Fripa.config.host = 'ipa.example.com'
Fripa.config.port = 8443      # optional
Fripa.config.scheme = 'https' # optional
Fripa.config.verify_ssl = false
```

### Advanced options

```ruby
Fripa.configure do |config|
  config.timeout = 30                    # read timeout in seconds (default: Faraday default)
  config.open_timeout = 5                # connect timeout in seconds (default: Faraday default)
  config.api_version = "2.251"           # FreeIPA API version sent with each call
  config.adapter = :net_http_persistent  # any Faraday adapter (default: Faraday.default_adapter)
  config.raise_on_partial_failure = true # raise Fripa::PartialFailureError (default: false)
end
```

The default adapter opens a new TCP/TLS connection for every request. If you
make many calls with one client, a keep-alive adapter is much faster. Add
`gem "faraday-net_http_persistent"` to your Gemfile and set
`config.adapter = :net_http_persistent`.

### Local development example

For local FreeIPA instances running on HTTP:

```ruby
Fripa.configure do |config|
  config.host = 'localhost'
  config.port = 8080
  config.scheme = 'http'
  config.verify_ssl = false
end
```

## Usage

### Creating a Client

#### Service account (shared client)

Put the credentials in the configuration and use `Fripa.client`. It is one
client for the whole process: it logs in on the first call, keeps the session,
and logs in again when the session expires. It is built again when the
configuration changes.

```ruby
Fripa.configure do |config|
  config.host = 'ipa.example.com'
  config.username = 'admin'
  config.password = 'secret'
end

Fripa.client.users.show('alice')
```

In tests, call `Fripa.reset_client!` before each test, so no session or test
double stays from one test to the next.

#### Other accounts

`Fripa::Client.new` creates a client for one account. It does not connect: it
logs in on the first call. Call `login!` to log in now, for example to check
credentials. It returns the session cookie.

```ruby
client = Fripa::Client.new(username: 'alice', password: 'her-password')

begin
  cookie = client.login!
rescue Fripa::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
end
```

To skip the login in later requests, build the client from the session cookie
(e.g. kept in an encrypted session):

```ruby
client = Fripa::Client.new(username: 'alice', session_cookie: cookie)
```

A client without a password cannot log in again: when its session expires, it
raises `Fripa::AuthenticationError`. With a `username`, `Fripa::Client.new`
never uses the password from the configuration. A client can be shared between
threads.

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

# Reset the password of another user (admin), without the current password
client.users.passwd("newuser", "NewPassword123")

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

##### Vaults

```ruby
client = Fripa::Client.new(username: 'admin', password: 'secret')

client.vault.add("my-vault", shared: true)
client.vault.archive("my-vault", data: "secret", shared: true)
client.vault.retrieve("my-vault", shared: true) # => "secret"
client.vault.add_member("my-vault", user: ["alice"], shared: true)
client.vault.delete("my-vault", shared: true)
```

By default, `archive` stores the raw bytes. The `ipa` CLI stores the data in a
JSON envelope (`{"data": "<base64>"}`). To share a vault with the `ipa` CLI
(`ipa vault-archive` / `ipa vault-retrieve`), pass `ipa_format: true`:

```ruby
client.vault.archive("my-vault", data: "secret", ipa_format: true, shared: true)
client.vault.retrieve("my-vault", ipa_format: true, shared: true) # => "secret"
```

The KRA transport certificate is fetched once per process and server, and all
clients share it (it is public and the same for every account). If the server
rejects a vault call, the certificate is fetched again on the next call.

#### Batch Calls

Send many commands in one HTTP request:

```ruby
result = client.batch(
  ["user_show", ["alice"]],
  ["group_find", [], { sizelimit: 0 }]
)
result.dig("result", "results").each { |r| puts r["error"] || r["result"] }
```

`batch` does not raise for errors in a single command. Check `error` in each result.
`batch!` raises `Fripa::BatchError` when any command failed. `#errors` lists them, with
the index, method, code, name and message of each:

```ruby
client.batch!(["vault_del", ["v1"]], ["vault_del", ["v2"]])
rescue Fripa::BatchError => e
  e.errors # => [{ index: 1, method: "vault_del", code: 4001, name: "NotFound", message: "v2: vault not found" }]
```

The vault resource builds batch commands with `add_command`, `archive_command`,
`add_member_command` and `delete_command`. They take the same arguments as `add`,
`archive`, `add_member` and `delete`, so you can set up many vaults in one request:

```ruby
vault = client.vault
client.batch!(*%w[v1 v2].flat_map do |cn|
  [vault.add_command(cn, shared: true),
   vault.archive_command(cn, data: "secret", shared: true),
   vault.add_member_command(cn, user: ["alice"], shared: true)]
end)
```

#### Using Raw API Calls

For API methods without a resource wrapper, use the `call` method directly:

```ruby
client = Fripa::Client.new(username: 'admin', password: 'secret')

# Any FreeIPA JSON-RPC method
result = client.call("user_find", ["admin"], { all: true })
puts result.dig("result", "count")
```

If the session expires (HTTP 401), the client logs in again and retries the call once.

### Error Handling

All errors inherit from `Fripa::Error`:

| Error | When |
|---|---|
| `Fripa::AuthenticationError` | Login fails |
| `Fripa::ConnectionError` | Network error, timeout, HTTP error status, or a response that is not JSON |
| `Fripa::ResponseError` | FreeIPA returns an error (`#code`, `#message`, `#data`) |
| `Fripa::PartialFailureError` | Only with `config.raise_on_partial_failure = true`. A subclass of `ResponseError`. The call succeeds but some entries fail, e.g. `group_add_member` with an unknown user. `#data` has the full `failed` hash |

By default, these per-entry failures do not raise. They stay in the response, in
`result["result"]["failed"]`. This will change in 1.0.

```ruby
begin
  client.groups.add_member("developers", user: ["alice"])
rescue Fripa::PartialFailureError => e
  e.data # => {"member" => {"user" => [["alice", "This entry is already a member"]], "group" => []}}
rescue Fripa::ResponseError => e
  puts "#{e.code}: #{e.message}"
end
```

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
