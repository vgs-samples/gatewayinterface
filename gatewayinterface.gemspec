# frozen_string_literal: true

$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), 'lib'))

require 'gatewayinterface/version'

Gem::Specification.new do |s|
  s.name = 'gatewayinterface'
  s.version = GatewayInterface::VERSION
  #  s.required_ruby_version = ">= 2.3.0"
  s.summary = "Ruby bindings that map Stripe's API to Braintree's API"
  s.description = 'GatewayInterface is a gem that maps the Stripe API to ' \
                  'the Braintree API instead to enable seamless transitions.'
  s.author = 'Very Good Security, Inc.'
  s.email = 'support@verygoodsecurity.com'
  s.homepage = 'https://verygoodsecurity.com'
  s.license = 'MIT'

  s.add_dependency 'activemerchant', '= 1.103.0'
  s.add_dependency 'braintree', '= 2.100.0'
  s.add_dependency 'dotenv', '= 2.7.5'
  s.add_dependency 'stripe', '= 5.11.0'

  s.metadata = {
  }

  s.files = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n")
                                           .map { |f| ::File.basename(f) }
  s.require_paths = ['lib']
end