# frozen_string_literal: true

require_relative "lib/fripa/version"

Gem::Specification.new do |spec|
  spec.name = "fripa"
  spec.version = Fripa::VERSION
  spec.authors = ["Bruno Costanzo"]
  spec.email = ["dev.bcostanzo@gmail.com"]

  spec.summary = "Ruby client for FreeIPA JSON-RPC API"
  spec.description = "A Ruby client library for FreeIPA's JSON-RPC API: users, groups, vaults and batch calls."
  spec.homepage = "https://github.com/renuo/fripa"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["source_code_uri"] = "https://github.com/renuo/fripa"
  spec.metadata["changelog_uri"] = "https://github.com/renuo/fripa/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/renuo/fripa/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/fripa"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base64", "~> 0.1"
  spec.add_dependency "faraday", "~> 2.0"
end
