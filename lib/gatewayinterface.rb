# frozen_string_literal: true

require_relative 'gatewayinterface/version'
require_relative 'gatewayinterface/resources'

module GatewayInterface # :nodoc:
  @current_gateway = nil

  class << self
    # These all get manual attribute writers so that we can reset connections
    # if they change.
    attr_reader :current_gateway
    attr_reader :_real_gateway
  end

  def self.current_gateway=(gateway)
    @current_gateway = gateway
  end

  GATEWAY_LIST = {
    stripe: ::Stripe,
    braintree: ::Braintree
  }.freeze

  def self._on_braintree(config)
    @current_gateway = ActiveMerchant::Billing::BraintreeBlueGateway.new(config)
    @_real_gateway = GatewayInterface::Braintree::Gateway.new(
      @current_gateway.instance_variable_get(:@configuration)
    )
  end

  def self._on_stripe(config)
    @current_gateway = ActiveMerchant::Billing::StripeGateway.new(config)
  end

  def self.configure(gateway, config:, description: '')
    unless GATEWAY_LIST.key?(gateway.to_sym)
      raise ArgumentError, <<~GATEWAYNOTFOUND
        #{gateway} is not supported in the GATEWAY_LIST.
        Check gatewayinterface.rb for the supported gateways or inspect
        GatewayInterface::GATEWAY_LIST
      GATEWAYNOTFOUND
    end

    case gateway.to_sym
    when :stripe
      _on_stripe config
    when :braintree
      _on_braintree config
    else
      raise ArgumentError, <<~GATEWAYNOTFOUND
        #{gateway} is not supported in the GATEWAY_LIST.
        Check gatewayinterface.rb for the supported gateways or inspect
        GatewayInterface::GATEWAY_LIST
      GATEWAYNOTFOUND
    end
  end
end
