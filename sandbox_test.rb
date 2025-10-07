#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "fripa"
require "faraday"
require "json"

puts "=== FreeIPA Sandbox Test ==="
puts

Fripa.configure do |config|
  config.host = "ipa.demo1.freeipa.org"
  config.username = "admin"
  config.password = "Secret123"
  config.verify_ssl = true
end

puts "Configuration:"
puts "  Host: #{Fripa.config.host}"
puts "  Username: #{Fripa.config.username}"
puts "  Base URL: #{Fripa.config.base_url}"
puts "  Login URL: #{Fripa.config.login_url}"
puts "  API URL: #{Fripa.config.api_url}"
puts

puts "Attempting authentication using Authenticator..."
authenticator = Fripa::Authenticator.new

begin
  authenticator.login!
  puts "✓ Authentication successful!"
  puts "Session cookie: #{Fripa.config.session_cookie&.split(";")&.first}"
rescue Fripa::AuthenticationError => e
  puts "✗ Authentication failed: #{e.message}"
  exit 1
end

puts "\nTrying API call (user_find)..."
conn = Faraday.new
api_response = conn.post(Fripa.config.api_url.to_s) do |req|
  req.headers["Content-Type"] = "application/json"
  req.headers["Referer"] = "https://#{Fripa.config.host}/ipa"
  req.headers["Cookie"] = Fripa.config.session_cookie
  req.body = {
    method: "user_find",
    params: [["admin"], { version: "2.251" }],
    id: 0
  }.to_json
end

puts "API Response Status: #{api_response.status}"
if api_response.status == 200
  result = JSON.parse(api_response.body)
  puts "✓ API call successful!"
  puts "\nResult summary:"
  puts "  Found #{result.dig("result", "count")} user(s)"
  if result.dig("result", "result", 0)
    user = result.dig("result", "result", 0)
    puts "  User: #{user["uid"]&.first}"
    puts "  Email: #{user["mail"]&.first}"
  end
else
  puts "✗ API call failed"
  puts api_response.body
end
