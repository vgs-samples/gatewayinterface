# frozen_string_literal: true

require ::File.expand_path('../test_helper', __dir__)

module GatewayInterface
  class InterfaceTest < Test::Unit::TestCase
    setup do
      puts 'called setup!'
      @stripe_api_key = ENV['STRIPE_API_KEY']
    end

    teardown do
      puts 'after2'
    end

    should 'allow access to underlying Stripe gem and its classes' do
      assert_equal(GatewayInterface::Stripe::Charge, ::Stripe::Charge)
    end

    should 'not have overridden the global Stripe namespace' do
      assert_equal(GatewayInterface::Stripe.ca_bundle_path, ::Stripe.ca_bundle_path)
    end

    should 'emulate specific Stripe client usage' do
      omit
      Stripe.api_key = @stripe_api_key
      token = Stripe::Token.create(card: {
                                     number: '4242424242424242',
                                     exp_month: 11,
                                     exp_year: 2025,
                                     cvc: '314'
                                   })
      provider_resource = Stripe::Token.retrieve(token.id)
      assert_equal token.id, provider_resource.id

      customer = Stripe::Customer.create(
        email: 'johnny@appleseed.com',
        source: token,
        description: 'a description'
      )

      provider_resource = Stripe::Customer.retrieve(customer.id)
      assert_equal customer.id, provider_resource.id

      amount = 1000
      currency = 'usd'
      token2 = Stripe::Token.create(card: {
                                      number: '4242424242424242',
                                      exp_month: 10,
                                      exp_year: 2024,
                                      cvc: '523'
                                    })
      source = Stripe::Source.create(
        type: 'card',
        token: token2.id
      )

      provider_resource = Stripe::Source.retrieve(source.id)
      assert_equal source.id, provider_resource.id

      description = 'Simple Charge Order'
      charge = Stripe::Charge.create(
        source: source.id,
        amount: amount,
        description: description,
        currency: currency
      )
      provider_resource = Stripe::Charge.retrieve(charge.id)
      assert_equal charge.id, provider_resource.id

      refund = Stripe::Refund.create(
        charge: charge
      )
      provider_resource = Stripe::Refund.retrieve(refund.id)
      assert_equal refund.id, provider_resource.id
    end

    should 'be listable' do
      assert_not_nil(GatewayInterface::Interface::Braintree::Charge.method(:retrieve))
    end

    should 'namespace change should delegate to ActiveMerchant' do

      #GatewayInterface.configure(
      #    'stripe',
      #    config: {
      #      login: ENV['STRIPE_API_KEY']
      #    })
      GatewayInterface.configure(
          'braintree',
          config: {
              environment: :sandbox,
              merchant_id: ENV['BRAINTREE_MERCHANT_ID'],
              public_key: ENV['BRAINTREE_PUBLIC_KEY'],
              private_key: ENV['BRAINTREE_PRIVATE_KEY']
          }
      )
      token = GatewayInterface::Interface::Braintree::Token.create(card: {
                                                          number: '4242424242424242',
                                                          exp_month: 11,
                                                          exp_year: 2025,
                                                          cvc: '314'
                                                        })
      provider_resource = GatewayInterface::Interface::Braintree::Token.retrieve(token.id)
      assert_equal token.id, provider_resource.id
      customer = GatewayInterface::Interface::Braintree::Customer.create(
        email: 'johnny@appleseed.com',
        source: token,
        description: 'a description'
      )

      provider_resource = GatewayInterface::Interface::Braintree::Customer.retrieve(customer.id)
      assert_equal customer.id, provider_resource.id

      amount = 1000
      currency = 'usd'
      token2 = GatewayInterface::Interface::Braintree::Token.create(card: {
                                                           number: '4242424242424242',
                                                           exp_month: 10,
                                                           exp_year: 2024,
                                                           cvc: '523'
                                                         })
      source = GatewayInterface::Interface::Braintree::Source.create(
        type: 'card',
        token: token2.id
      )
      provider_resource = GatewayInterface::Interface::Braintree::Source.retrieve(source.id)
      assert_equal source.id, provider_resource.id

      description = 'Simple Charge Order'
      charge = GatewayInterface::Interface::Braintree::Charge.create(
        source: source.id,
        amount: amount,
        description: description,
        currency: currency
      )
      provider_resource = GatewayInterface::Interface::Braintree::Charge.retrieve(charge.id)
      assert_equal charge.id, provider_resource.id

      # Only difference is to force transaction to settle
      # https://developers.braintreepayments.com/reference/general/testing/ruby#settlement-status
      result = GatewayInterface._real_gateway.testing.settle(charge.id)
      assert_equal(
        result.transaction.status,
        ::Braintree::Transaction::Status::Settled
      )

      refund = GatewayInterface::Interface::Braintree::Refund.create(
        charge: charge
      )
      provider_resource = GatewayInterface::Interface::Braintree::Refund.retrieve(refund.id)
      assert_equal refund.id, provider_resource.id
    end
  end
end
