# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/renuo/fripa/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/renuo/fripa/compare/v0.1.4...v0.2.0
[0.1.4]: https://github.com/renuo/fripa/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/renuo/fripa/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/renuo/fripa/compare/v0.1.0...v0.1.2
[0.1.0]: https://github.com/renuo/fripa/releases/tag/v0.1.0
