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
    # Primary responsibility of initialize is to instantiate the
    # attributes of the service object with the expected values.
    def initialize(attributes = {})
      self.class.defaults.merge(attributes).each do |key, value|
        send("#{key}=", value)
      end

      super
      yield self if block_given?
    end

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

    def call
      self.result = __call if valid?
      self
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
        new(args).call
      end

      ##
      # When the subclass overwrites the #call method, reassign it to #__call.
      # This allows us to still control what happens in the instance level of #call.
      def method_added(method_name)
        if method_name == :call
          alias_method :__call, :call
          send(:remove_method, :call)
        else
          super
        end
      end
    end
  end
end
