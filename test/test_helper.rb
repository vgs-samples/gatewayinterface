# frozen_string_literal: true

require 'gatewayinterface'
require 'test/unit'
require 'stringio'
require 'shoulda/context'
require 'shoulda/matchers'


PROJECT_ROOT = ::File.expand_path('../', __dir__)


module Test
  module Unit
    class TestCase

      setup do
        puts 'before'
      end

      teardown do
        puts 'after'
      end

    end
  end
end