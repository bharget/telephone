# frozen_string_literal: true

require "active_model"

module Telephone
  class Service
    include ActiveModel::Model

    ##
    # The primary outcome of the service object. For consistency,
    # all service objects always return +self+. If you need a value
    # returned, the return value of +#call+ will be available on the
    # attribute +@result+.
    #
    # @example
    #   Telephone::Service.call(foo: bar).result # "baz"
    attr_accessor :result

    ##
    # Determines whether or not the action of the service
    # object was successful.
    #
    # @example
    #   Telephone::Service.call(foo: bar).success? # true
    #
    # @return [Boolean] whether or not the action succeeded.
    def success?
      errors.empty?
    end

    class << self
      ##
      # Defines a getter/setter for a service object argument. This also allows you
      # to pass in a default, or set the argument to "required" to add a validation
      # that runs before executing the block.
      #
      # @example
      #   class SomeService < Telephone::Service
      #     argument :foo, default: "bar"
      #     argument :baz, required: true
      #
      #     def call
      #       puts foo
      #       puts baz
      #     end
      #   end
      def argument(arg, default: nil, required: false)
        send(:attr_accessor, arg.to_sym)
        send(:validates, arg.to_sym, presence: true) if required

        defaults[arg.to_sym] = default
      end

      ##
      # Used to maintain a list of default values to set prior to initialization
      # based on the options in #argument.
      def defaults
        @defaults ||= {}
      end

      ##
      # Executes the service object action directly from the class — similar to the
      # way a Proc can be executed with `Proc#call`. This allows us to add some common
      # logic around running validations and setting argument defaults.
      #
      # @example
      #   Telephone::Service.call(foo: bar)
      def call(**args)
        instance = new(defaults.merge(args))
        instance.result = instance.call if instance.valid?
        instance
      end
    end
  end
end
