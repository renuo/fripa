# Contributing to Fripa

Thank you for your interest in contributing to Fripa! This document provides guidelines and instructions for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs. actual behavior
- Your Ruby version and FreeIPA version
- Any relevant code samples or error messages

### Suggesting Features

Feature suggestions are welcome! Please open an issue with:
- A clear description of the feature
- Use cases explaining why this feature would be useful
- Any implementation ideas you might have

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding standards
3. **Add tests** for any new functionality
4. **Ensure all tests pass** by running `bin/test`
5. **Run the linter** with `bundle exec rubocop`
6. **Update documentation** if you're changing functionality
7. **Submit your pull request** with a clear description of changes

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/brunocostanzo/fripa.git
   cd fripa
   ```

2. Install dependencies:
   ```bash
   bin/setup
   ```

3. Run tests:
   ```bash
   bin/test
   ```

4. Run linter:
   ```bash
   bundle exec rubocop
   ```

## Coding Standards

- Follow the [Ruby Style Guide](https://rubystyle.guide/)
- Use RuboCop to check your code style
- Write clear, self-documenting code
- Add comments for complex logic
- Keep methods small and focused
- Maintain test coverage above 95%

## Testing Guidelines

- Write tests for all new features
- Update tests when modifying existing features
- Use VCR cassettes for API interactions
- Ensure both line and branch coverage remain high
- Test both success and error cases

## Commit Messages

Write clear, descriptive commit messages:
- Use present tense ("Add feature" not "Added feature")
- Capitalize the first letter
- Keep the first line under 72 characters
- Add detailed description if needed

Example:
```
Add support for host management

- Implement host resource with CRUD operations
- Add tests with VCR cassettes
- Update README with usage examples
```

## Questions?

If you have questions about contributing, feel free to open an issue labeled "question".

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).
