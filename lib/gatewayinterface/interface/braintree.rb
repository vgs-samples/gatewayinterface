# frozen_string_literal: true

module GatewayInterface #:nodoc:
  module Interface #:nodoc:
    module Braintree #:nodoc:
      # for braintree, when you add a source or a card, you must use a Nonce
      # here's how you can use it:
      #    https://github.com/braintree/braintree_ruby/blob/master/spec/integration/braintree/client_api/spec_helper.rb
      #
      #

      class SimpleResource < ::Stripe::StripeObject
        def self.braintree_gateway
          gateway.instance_variable_get(:@braintree_gateway)
        end

        def self.configuration
          gateway.instance_variable_get(:@configuration)
        end

        def self.gateway
          GatewayInterface.current_gateway
        end
      end

      class Customer < SimpleResource
        # source:
        #   - Hash or String
        #
        # options - Optional values that can be passed with a request.
        #
        #  - :fail_on_duplicate_payment_method, bool,
        #
        #    If this option is passed and the same payment method has
        #    already been added to the Vault for any customer, the
        #    request will fail.
        #
        #  - :make_default, bool,
        #
        #    This option makes the specified payment method the default
        #    for the customer.
        #
        #  - :verification_amount, String,
        #
        #    Specify a non-negative amount that you want to use to verify
        #    a card. If you do not pass this option, the gateway will
        #    automatically use a verification amount of $0 or $1, depending
        #    on the processor and/or card type.
        #
        #  - :verification_merchant_account_id, String,
        #
        #    Specify the merchant account ID that you want to use to
        #    verify a card. See the merchant_account_id on
        #    Transaction.sale() to learn more. The merchant account can't
        #    be a marketplace sub-merchant account. See the Braintree
        #    Marketplace Guide to learn more.
        #
        #  - :verify_card, bool,
        #
        #    This option prompts the gateway to verify the card's number
        #    and expiration date. It also verifies the AVS and CVV
        #    information if you've enabled AVS and CVV rules.
        #
        #    NOTE: Braintree strongly recommends verifying all cards
        #    before they are stored in your Vault by enabling card
        #    verification for your entire account in the Control Panel.
        #
        #    In some cases, cardholders may see a temporary authorization
        #    on their account after their card has been verified. The
        #    authorization will fall off the cardholder's account within
        #    a few days and will never settle.
        #
        #    Only returns a CreditCardVerification result if verification
        #    runs and is unsuccessful.
        def self.create(email: nil,
                        source: nil,
                        description: nil,
                        billing_address: nil,
                        options: {})
          # TODO: description should be a custom field setup in Braintree control
          # panel
          #
          # if the source is a hash, then we are passing down the card information
          # so we should just call source card and create the customer as well.
          card_options = options.merge(
            email: email,
            billing_address: billing_address
          )
          card_options = Utils.indifferent_read_access(card_options)
          resp = nil
          if source.is_a?(Hash)
            resp = Source._create_card(source, options: card_options)
            return retrieve(resp.params[:customer_vault_id])
          elsif source.is_a?(String)
            card_options.merge!(payment_method_token: source)
            resp = gateway.store(
              ActiveMerchant::Billing::CreditCard.new,
              card_options
            )
            return _as_customer(resp)
          elsif source.nil?
            bt_result = braintree_gateway.customer.create(
              email: email,
              billing_address: billing_address
            )
            resp = _build_resp_from_bt_result(bt_result)
            return _as_customer(resp)
          elsif source.is_a?(Token)

            if billing_address.nil? || billing_address.empty?
              resp = braintree_gateway.payment_method.update(source.id, {})
            else
              bill_options = billing_address[:options] || {}
              bill_options.merge!(update_existing: true)
              billing_address[:options] = bill_options
              resp = braintree_gateway.payment_method.update(
                source.id,
                billing_address: billing_address
              )
            end
            raise 'Failure to update customer' unless resp.success?

            # we will have to do an update for the customer
            bt_result = braintree_gateway.customer.update(
              source.customer_vault_id,
              email: email
            )
            resp = _build_resp_from_bt_result(bt_result)
            return _as_customer(resp)
          end
        end

        # TODO: what to do when customer not found?
        def self.retrieve(id)
          bt_result = braintree_gateway.customer.find(id)
          resp = _build_resp_from_bt_result(
            ::Braintree::SuccessfulResult.new(customer: bt_result)
          )
          _as_customer(resp)
        end

        def self._as_customer(response)
          customer = new(id: response.params['customer_vault_id'])
          customer.update_attributes(response.params)
          customer
        end

        def self._build_resp_from_bt_result(bt_result)
          ActiveMerchant::Billing::Response.new(
            bt_result.success?,
            gateway.send(:message_from_result, bt_result),
            {
              braintree_customer: (
              if bt_result.success?
                gateway.send(
                  :customer_hash,
                  bt_result.customer, include_credit_cards: true
                )
              end),
              customer_vault_id: (bt_result.customer.id if bt_result.success?),
              credit_card_token: (bt_result.customer.credit_cards[0].token if bt_result.success?)
            },
            authorization: (bt_result.customer.id if bt_result.success?)
          )
        end
      end

      class Charge < SimpleResource
        def self.create(source: nil,
                        amount: nil,
                        auth: false,
                        **params)
          options = {}
          options.merge!(
            currency: params[:currency],
          )
          card_details = nil
          if source.is_a?(Hash)
            card_details = ActiveMerchant::Billing::CreditCard.new(
              Source._map_card_details(source)
            )
          elsif source.is_a?(String)
            card_details = source
            options[:payment_method_token] = true
          end

          method = if auth
                     gateway.method(:authorize)
                   else
                     options[:submit_for_settlement] = true
                     gateway.method(:purchase)
                   end

          resp = method.call(amount, card_details, options)
          _as_charge(resp)
        end

        def self._as_charge(response)
          charge = new(id: response.authorization)
          charge.update_attributes(response.params)
          charge
        end

        def self.retrieve(id)
          result = ::Braintree::SuccessfulResult.new(
            transaction: braintree_gateway.transaction.find(id)
          )
          response = ActiveMerchant::Billing::Response.new(
            result.success?,
            gateway.send(:message_from_transaction_result, result),
            gateway.send(:response_params, result),
            gateway.send(:response_options, result)
          )
          response.params['braintree_transaction']['amount'] = (
          result.transaction.amount.to_i * 100
        )
          response.cvv_result['message'] = ''
          _as_charge(response)
        end
      end

      class Refund < SimpleResource
        def self.create(charge:, amount: nil)
          if !charge.is_a?(String) && charge.respond_to?(:id)
            charge = charge.id
          end
          resp = gateway.refund(
            amount,
            charge,
            options: { force_full_refund_if_unsettled: true }
          )
          _as_refund(resp)
        end

        def self._as_refund(response)
          refund = new(id: response.authorization)
          refund.update_attributes(response.params)
          refund
        end

        def self.retrieve(id)
          result = ::Braintree::SuccessfulResult.new(
            transaction: braintree_gateway.transaction.find(id)
          )
          response = gateway.send(:response_from_result, result)
          _as_refund(response)
        end
      end

      class Source < SimpleResource
        def self._supported_sources
          ['card']
        end

        # TODO: what about adding to a customer?
        def self.create(type: nil, token: nil, card: nil)
          unless _supported_sources.include?(type)
            raise ArgumentError, <<~WRONGTYPE
              #{type} is not a supported source. Either add support in
               interface/braintree.rb or select one of the
               sources in #{_supported_sources.join(', ')}
            WRONGTYPE
          end

          if !token.nil?
            return _on_token(type, token)
          elsif !card.nil?
            return _on_token(type, card)
          end
        end

        def self._on_token(type, token)
          return _fetch_card(token) if (type == 'card') && token.is_a?(String)

          _fetch_card(token) if (type == 'card') && token.is_a?(Hash)
        end

        def self._on_card(type, card)
          return _create_card(card) if (type == 'card') && card.is_a?(Hash)

          _fetch_card(card) if (type == 'card') && card.is_a?(String)
        end

        #
        # options:
        #   - payment_method_nonce
        #   - credit_card_token
        #   - email
        #   - billing_address.phone
        #   - customer
        #   - device_data
        def self._create_card(card_details, options: {})
          card_details = _map_card_details(card_details)
          stored_resp = gateway.store(
            card_details,
            options
          )
          _as_source(stored_resp)
        end

        def self._map_card_details(card_details)
          mappings = {
            number: :number,
            exp_month: :month,
            exp_year: :year,
            cvc: :verification_value
          }
          card_details = card_details.each_with_object({}) do |(k, v), memo|
            memo[mappings[k]] = v || k
          end
          card_details
        end

        def self._as_source(response)
          source = new(id: response.params['credit_card_token'])
          source.update_attributes(response.params)
          source
        end

        def self._fetch_card(token)
          result = ::Braintree::SuccessfulResult.new(
            credit_card: braintree_gateway.credit_card.find(token)
          )
          response = ActiveMerchant::Billing::Response.new(
            result.success?,
            gateway.send(:message_from_result, result), {
              credit_card: result.credit_card,
              customer_vault_id: result.credit_card.customer_id,
              credit_card_token: result.credit_card.token
            },
            test: gateway.test?
          )
          _as_source(response)
        end

        def self.retrieve(id)
          _fetch_card(id)
        end
      end

      class Token < SimpleResource
        def self.create(card: {})
          cc = ActiveMerchant::Billing::CreditCard.new(
            month: card[:exp_month],
            year: card[:exp_year],
            number: card[:number],
            verification_value: card[:cvc]
          )
          response = gateway.store(cc, options: {})
          # the token on the response here is the ID
          token = new(id: response.params['credit_card_token'])
          token.update_attributes(response.params)
          token
        end

        def self.retrieve(id)
          Source.retrieve(id)
        end
      end
    end
  end
end
