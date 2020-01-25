# frozen_string_literal: true

require ::File.expand_path('../test_helper', __dir__)

# what we want here is to use active merchant instead of just monkey patching Stripe.
# This is a *way* better plan than monkey patching *all* of Stripe.
# we can just build an adapter to the Stripe client with the ActiveMerchant stuff instead.

module GatewayInterface
  class AcceptanceTest < Test::Unit::TestCase

    should 'when imported, should allow Stripe to be monkey patched' do
      begin
        assert_nil Stripe.has_instance_method?('gateway_engine')
        assert_true Stripe.has_instance_method?('gateway_engine')
      ensure
      end
    end

    should 'set gateway engine to braintree' do
      begin
        require 'stripe2gatewapp'
        Stripe.set_gateway_engine(GatewayInterface::Braintree)
        assert_equal(Stripe.gateway_engine, GatewayInterface::Braintree)
      ensure
        Stripe.set_gateway_engine(GatewayInterface::Stripe)
      end
    end

    should 'allow access to underlying Stripe module when needed' do
      begin
        require 'stripe2gatewapp'
        Stripe.set_gateway_engine(GatewayInterface::Braintree)
        # assert Stripe::
      end
    end
  end
end