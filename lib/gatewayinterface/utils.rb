# frozen_string_literal: true

module GatewayInterface
  module Utils

    def self.equires!(hash, *params)
      params.each do |param|
        if param.is_a?(Array)
          raise ArgumentError, "Missing required parameter: #{param.first}" unless hash.key?(param.first)

          valid_options = param[1..-1]
          raise ArgumentError, "Parameter: #{param.first} must be one of #{valid_options.to_sentence(words_connector: 'or')}" unless valid_options.include?(hash[param.first])
        else
          raise ArgumentError, "Missing required parameter: #{param}" unless hash.key?(param)
        end
      end
    end

    def self.indifferent_read_access(base = {})
      indifferent = Hash.new do |hash, key|
        hash[key.to_s] if key.is_a? Symbol
      end
      base.each_pair do |key, value|
        if value.is_a? Hash
          value = indifferent_read_access value
        elsif value.respond_to? :each
          if value.respond_to? :map!
            value.map! do |v|
              if v.is_a? Hash
                v = indifferent_read_access v
              end
              v
            end
          else
            value.map do |v|
              if v.is_a? Hash
                v = indifferent_read_access v
              end
              v
            end
          end
        end
        indifferent[key.to_s] = value
      end
      indifferent
    end

  end
end
