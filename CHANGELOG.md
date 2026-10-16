# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.4.0] - 2026-10-16

### Added
- `Fripa::Client#batch!`: like `batch`, but raises `Fripa::BatchError` (a `Fripa::ResponseError`) when any command failed. `#errors` lists each failed command (index, method, code, name, message); `#code` and `#message` are those of the first one.
- Vault batch commands: `vault.add_command`, `archive_command`, `add_member_command` and `delete_command` return `[method, args, options]` for `Client#batch`, so many vault operations go in one request. `archive_command` wraps the data with the transport certificate, like `archive`. When a transport command fails in `batch!`, the certificate is forgotten and fetched again on the next call, as with `archive`.

## [0.3.0] - 2026-10-15

### Changed
- **`Fripa::Client.new` no longer connects.** The client logs in on the first call. Wrong credentials now raise `Fripa::AuthenticationError` on the first call, not in `Client.new`. Call `client.login!` to log in at once. Blank credentials still raise `ArgumentError` in `Client.new`.
- The vault transport certificate is cached per process and server URL, so all clients share it (before: one fetch per client). It is fetched again after a vault call fails.

### Added
- `Fripa.client`: one client for the account in `config.username` / `config.password`, shared by the process. It is built on first use and again when the configuration changes. `Fripa.reset_client!` forgets the shared client (e.g. between tests).
- `Fripa::Client#login!` (returns the session cookie) and `#logged_in?`.
- `Fripa::Client.new(username:, session_cookie:)` builds a client from an earlier session, without a login request. `password` is now optional. Without a password, an expired session raises `Fripa::AuthenticationError`.
- `Fripa::Client.new` without `username` uses the credentials from the configuration. With a `username`, it never uses the configured password.
- `Configuration#inspect` does not show the password.

## [0.2.0] - 2026-10-12

### Changed
- Network errors and timeouts (`Faraday::Error`) now raise `Fripa::ConnectionError`. Responses that are not JSON also raise `Fripa::ConnectionError`.
- The session cookie keeps only `name=value` pairs. Attributes like `path`, `httponly` and `secure` are no longer sent back.
- Login and API calls share one HTTP connection.
- `Fripa::Client#inspect` and `Fripa::Authenticator#inspect` no longer show the password or the session cookie.
- `scheme` is case-insensitive. An unknown scheme raises `ArgumentError` instead of falling back to HTTP.

### Added
- `config.raise_on_partial_failure` (default `false`): when `true`, calls that report per-entry failures (e.g. `group_add_member` with an unknown user, or a user that is already a member) raise `Fripa::PartialFailureError` (a `Fripa::ResponseError`). The full `failed` hash is in `#data`.
- The client logs in again and retries once when the session expires (HTTP 401).
- `Fripa::Client#batch` sends many commands in one HTTP request.
- Configuration options: `timeout`, `open_timeout`, `api_version` and `adapter` (e.g. `:net_http_persistent` for keep-alive).
- `ipa_format:` option for `vault.archive` and `vault.retrieve`, to read and write vaults in the format of the `ipa` CLI.
- `users.passwd` accepts no current password, so admins can reset the password of another user.
- RBS signatures in `sig/`.

### Fixed
- `vault.retrieve` returns `nil` for an empty vault instead of raising `NoMethodError`.
- The vault resource fetches the KRA transport certificate once per client, not on every archive and retrieve.

## [0.1.4] - 2026-04-16

### Added
- Vault resource: `add`, `show`, `archive`, `retrieve`, `add_member`, `delete`, with transport encryption (AES-128-CBC session key wrapped with the KRA transport certificate).

## [0.1.3] - 2025-11-26

### Added
- `Fripa::ResponseError` with `#code`, `#message` and `#data` for errors returned by FreeIPA.

## [0.1.2] - 2025-11-14

### Fixed
- Fixed `Fripa.configure` block syntax not working due to missing required `host` parameter in Configuration initializer
- Configuration validation now happens at usage time instead of initialization time

## [0.1.0] - 2025-10-07

Initial release of Fripa - A Ruby client for the FreeIPA JSON-RPC API.

### Added
- FreeIPA client with automatic authentication
- User resource management (find, show, add, modify, delete, password change)
- Group resource management (find, show, add, modify, delete)
- Group membership operations (add/remove members and member managers)
- Global configuration system with multiple configuration styles
- Comprehensive error handling with custom exception classes
- Parameter validation for resource methods
- Full test suite with VCR cassettes
- Complete API documentation and usage examples

[Unreleased]: https://github.com/renuo/fripa/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/renuo/fripa/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/renuo/fripa/compare/v0.1.4...v0.2.0
[0.1.4]: https://github.com/renuo/fripa/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/renuo/fripa/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/renuo/fripa/compare/v0.1.0...v0.1.2
[0.1.0]: https://github.com/renuo/fripa/releases/tag/v0.1.0
