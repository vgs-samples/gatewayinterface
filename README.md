# GatewayInterface

This application helps with the transition from a specific payment gateway (i.e. Stripe) to another payments gateway via an abstraction.

## Instructions

## Stripe

### To access the underlying raw gem

If you need to access the underlying gem, there is a convenient helper included that allows you to access the underlying gem. 

This is located in `lib/gatewayinterface/stripe` and is equivalent to accessing the `Stripe` gem directly.

```ruby
GatewayInterface::Stripe == ::Stripe
```

### Migrating config from Stripe to GatewayInterface 

When configuring `Stripe`, this is the code that is used to configure:

```ruby
Stripe.api_key = sk_test_1111111111111 # example
``` 

This is how to you migrate to `GatewayInterface`:

```ruby
GatewayInterface.configure('stripe', {:login => 'sk_test_1111111111111'})
```

If your `Stripe` gem is in your gem path, `GatewayInterface` will also configure `Stripe`'s api key configuration for you.

### Configuring additional payment gateways

For this example, we will configure `Braintree`:

```ruby
GatewayInterface.configure(
          'braintree',
          config: {
              environment: :sandbox,  # change to production for production
              merchant_id: ENV['BRAINTREE_MERCHANT_ID'],
              public_key: ENV['BRAINTREE_PUBLIC_KEY'],
              private_key: ENV['BRAINTREE_PRIVATE_KEY']
          }
      )
```

### Migrating transactions from Stripe to GatewayInterface

Replace `GatewayInterface::Stripe` to `GatewayInterface::Interface::Stripe`

### Migrating transactions from Stripe to Braintree

Replace `GatewayInterface::Stripe` to `GatewayInterface::Interface::Braintree`
 