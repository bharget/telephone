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
      attributes = attributes.transform_keys(&:to_sym)

      attributes.each do |key, value|
        send("#{key}=", value)
      end

      self.class.defaults.each do |key, value|
        next if attributes.key?(key)

        resolved = if value.is_a?(Proc)
          instance_exec(&value)
        elsif value.respond_to?(:call)
          value.call
        else
          value
        end

        send("#{key}=", resolved)
      end

      validate_required_arguments!(attributes)

      super
      yield self if block_given?
    end

    def validate_required_arguments!(attributes)
      self.class.required_arguments.each do |arg|
        unless attributes.key?(arg)
          raise ArgumentError, "missing required argument: #{arg}"
        end
      end
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
      # Defines a getter/setter for a service object argument.
      #
      # @param arg [Symbol] The name of the argument
      # @param default [Object, Proc] Default value or callable that returns the default
      # @param required [Boolean] If true, raises ArgumentError if argument is not provided
      # @param validates [Hash] ActiveModel validation options to apply
      #
      # The default value can be a static value or any callable object (Proc, lambda,
      # method, or any object that responds to #call) that will be evaluated at
      # runtime when the service is instantiated.
      #
      # Callable defaults are evaluated in the context of the service instance,
      # so they can access other attributes. They are processed in definition order,
      # meaning a callable can depend on any argument defined before it.
      #
      # The +required+ option checks if the argument key was provided, not if the
      # value is present. Passing +nil+ explicitly satisfies the requirement.
      #
      # To store a Proc as the actual value, wrap it in another lambda:
      #   argument :my_proc, default: -> { -> { puts "hi" } }
      #
      # @example Basic usage
      #   argument :name, default: "John"
      #   argument :name, required: true
      #
      # @example With validations
      #   argument :email, validates: { format: { with: /@/ } }
      #   argument :name, required: true, validates: { length: { minimum: 2 } }
      #
      # @example With callable defaults
      #   class SomeService < Telephone::Service
      #     argument :first_name, default: "John"
      #     argument :last_name, default: "Doe"
      #     argument :full_name, default: -> { "#{first_name} #{last_name}" }
      #   end
      def argument(arg, default: nil, required: false, validates: nil)
        attr_accessor(arg.to_sym)
        required_arguments << arg.to_sym if required
        validates(arg.to_sym, validates) if validates

        defaults[arg.to_sym] = default
      end

      ##
      # Used to maintain a list of default values to set prior to initialization
      # based on the options in #argument.
      def defaults
        @defaults ||= {}
      end

      def required_arguments
        @required_arguments ||= []
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
