# frozen_string_literal: true

RSpec.describe Telephone::Service do
  subject do
    Class.new(Telephone::Service) do
      argument :foo, default: "bar"

      def call
        foo
      end
    end
  end

  it { expect(subject).to respond_to(:call) }
  it { expect(subject).to respond_to(:argument) }
  it { expect(subject.new).to respond_to(:result) }
  it { expect(subject.new).to respond_to(:result=) }

  describe "#argument" do
    it "allows setting a default" do
      expect(subject.call.foo).to be "bar"
    end

    it "allows overwriting the default" do
      expect(subject.call(foo: "baz").foo).to be "baz"
    end

    it "allows passing a hash of arguments" do
      expect(subject.call({foo: "baz"}).foo).to be "baz"
    end

    it "merges a hash with keyword arguments" do
      subject.public_send(:argument, :bar, default: "qux")

      expect(subject.call({foo: "baz"}, bar: "override").bar).to be "override"
    end

    it "allows requiring an argument" do
      subject.public_send(:argument, :required_field, required: true)

      expect(subject.call.success?).to be false
    end

    context "with type validation" do
      user_class = Struct.new(:name, keyword_init: true)

      def build_service(&block)
        Class.new(Telephone::Service) do
          def self.name = "TypeValidationService"

          class_eval(&block)
        end
      end

      it "allows a value of the expected type" do
        service = build_service do
          argument :user, type: user_class

          def call
            user
          end
        end

        user = user_class.new(name: "Jane")
        instance = service.new(user: user)

        expect(instance).to be_valid
        expect(instance.call.success?).to be true
      end

      it "rejects a value of the wrong type" do
        service = build_service do
          argument :user, type: user_class
        end

        instance = service.new(user: "not a user")

        expect(instance).not_to be_valid
        expect(instance.errors[:user]).to include("must be a #{user_class.name || user_class}")
        expect(instance.errors.details[:user]).to include(error: :invalid_type, type: user_class.name || user_class.to_s)
        expect(instance.call.success?).to be false
      end

      it "uses the I18n translation for type errors" do
        service = build_service do
          argument :name, type: String
        end

        instance = service.new(name: 123)

        expect(instance).not_to be_valid
        expect(instance.errors[:name]).to include("must be a String")
      end

      it "uses the locale-specific translation when I18n locale is changed" do
        service = build_service do
          argument :name, type: String
        end

        instance = service.new(name: 123)

        I18n.with_locale(:es) do
          expect(instance.tap(&:valid?).errors[:name]).to include("debe ser un String")
        end
      end

      it "allows nil when the argument is optional" do
        service = build_service do
          argument :user, type: user_class

          def call
            user
          end
        end

        instance = service.new

        expect(instance).to be_valid
        expect(instance.call.success?).to be true
      end

      it "works with required arguments" do
        service = build_service do
          argument :user, type: user_class, required: true
        end

        expect(service.new.valid?).to be false
        expect(service.new(user: "not a user").valid?).to be false
        expect(service.new(user: user_class.new(name: "Jane")).valid?).to be true
      end

      it "validates default values" do
        service = build_service do
          argument :user, type: user_class, default: "not a user"
        end

        instance = service.new

        expect(instance).not_to be_valid
        expect(instance.errors[:user]).to include("must be a #{user_class.name || user_class}")
      end
    end

    context "with sequential argument validations" do
      def build_service(&block)
        Class.new(Telephone::Service) do
          def self.name = "SequentialValidationService"

          class_eval(&block)
        end
      end

      it "skips custom validations when a required argument is missing" do
        custom_ran = false
        service = build_service do
          argument :object, required: true, type: Hash

          validate do
            custom_ran = true
            errors.add(:object, "must have user key") unless object.key?(:user)
          end
        end

        instance = service.new

        expect(instance).not_to be_valid
        expect(custom_ran).to be false
        expect(instance.errors[:object]).to include("can't be blank")
        expect(instance.errors[:object]).not_to include("must have user key")
      end

      it "skips custom validations when an argument has the wrong type" do
        custom_ran = false
        service = build_service do
          argument :object, required: true, type: Hash

          validate do
            custom_ran = true
            errors.add(:object, "must have user key") unless object.key?(:user)
          end
        end

        instance = service.new(object: "not a hash")

        expect(instance).not_to be_valid
        expect(custom_ran).to be false
        expect(instance.errors[:object]).to include("must be a Hash")
        expect(instance.errors[:object]).not_to include("must have user key")
      end

      it "runs custom validations when argument validations pass" do
        custom_ran = false
        service = build_service do
          argument :object, required: true, type: Hash

          validate do
            custom_ran = true
            errors.add(:object, "must have user key") unless object.key?(:user)
          end
        end

        instance = service.new(object: {other: true})

        expect(instance).not_to be_valid
        expect(custom_ran).to be true
        expect(instance.errors[:object]).to include("must have user key")
      end

      it "allows custom validations to assume presence and type" do
        service = build_service do
          argument :object, required: true, type: Hash

          validate :contains_user_key

          def contains_user_key
            return if object.key?(:user)

            errors.add(:object, "must have user key")
          end
        end

        expect(service.new).not_to be_valid
        expect(service.new(object: "nope")).not_to be_valid

        missing_key = service.new(object: {other: true})
        expect(missing_key).not_to be_valid
        expect(missing_key.errors[:object]).to include("must have user key")

        expect(service.new(object: {user: 1})).to be_valid
      end
    end

    context "with callable defaults" do
      it "evaluates callable defaults fresh on each instantiation" do
        counter = {value: 0}
        service = Class.new(Telephone::Service) do
          argument :count, default: proc { counter[:value] += 1 }

          def call
            count
          end
        end

        expect(service.new.count).to eq 1
        expect(service.new.count).to eq 2
        expect(service.new.count).to eq 3
      end

      it "works with any object responding to #call" do
        callable_object = Class.new do
          def call
            "from callable object"
          end
        end.new

        service = Class.new(Telephone::Service) do
          argument :value, default: callable_object

          def call
            value
          end
        end

        expect(service.new.value).to eq "from callable object"
      end

      it "allows overriding callable defaults with explicit values" do
        service = Class.new(Telephone::Service) do
          argument :value, default: -> { "default" }
        end

        expect(service.new(value: "custom").value).to eq "custom"
      end

      it "does not call non-callable defaults" do
        service = Class.new(Telephone::Service) do
          argument :data, default: "static string"

          def call
            data
          end
        end

        expect(service.new.data).to eq "static string"
      end

      it "allows callables to access other attributes" do
        service = Class.new(Telephone::Service) do
          argument :first_name, default: "John"
          argument :last_name, default: "Doe"
          argument :full_name, default: -> { "#{first_name} #{last_name}" }

          def call
            full_name
          end
        end

        expect(service.new.full_name).to eq "John Doe"
      end

      it "allows callables to depend on other callables in definition order" do
        service = Class.new(Telephone::Service) do
          argument :first_name, default: "John"
          argument :last_name, default: "Doe"
          argument :full_name, default: -> { "#{first_name} #{last_name}" }
          argument :greeting, default: -> { "Hello, #{full_name}!" }

          def call
            greeting
          end
        end

        expect(service.new.greeting).to eq "Hello, John Doe!"
      end

      it "allows callables to access explicitly provided attributes" do
        service = Class.new(Telephone::Service) do
          argument :first_name
          argument :last_name
          argument :full_name, default: -> { "#{first_name} #{last_name}" }

          def call
            full_name
          end
        end

        expect(service.new(first_name: "Jane", last_name: "Smith").full_name).to eq "Jane Smith"
      end

      it "processes explicit attributes before callable defaults" do
        service = Class.new(Telephone::Service) do
          argument :name, default: "Default"
          argument :message, default: -> { "Hello, #{name}!" }

          def call
            message
          end
        end

        expect(service.new(name: "Custom").message).to eq "Hello, Custom!"
      end
    end
  end

  describe "#new" do
    it "sets defaults" do
      expect(subject.new.foo).to be "bar"
    end

    it "accepts default overrides" do
      expect(subject.new(foo: "baz").foo).to be "baz"
    end

    it "accepts string keys" do
      expect(subject.new("foo" => "baz").foo).to eq "baz"
    end

    it "handles string keys with callable defaults" do
      service = Class.new(Telephone::Service) do
        argument :name, default: "Default"
        argument :message, default: -> { "Hello, #{name}!" }
      end

      expect(service.new("name" => "Custom").message).to eq "Hello, Custom!"
    end

    context "if there is a required argument" do
      before { subject.public_send(:argument, :required_field, required: true) }

      it "cannot call without the required argument" do
        instance = subject.new
        expect(instance.valid?).to be false
        expect(instance.call).to be_a Telephone::Service
        expect(instance.call.success?).to be false
      end

      it "works as expected with the required argument" do
        instance = subject.new(required_field: "baz")

        expect(instance.required_field).to be "baz"
        expect(instance.call.success?).to be true
        expect(instance.call.result).to be instance.foo
        expect(instance.call).to be_a Telephone::Service
      end
    end
  end

  describe "#call" do
    context "when validations pass" do
      before do
        subject.any_instance.stubs(valid?: true)
      end

      it "calls the instance level #call" do
        subject.any_instance.expects(:call).once

        subject.call
      end

      it "sets instance.result" do
        subject.any_instance.expects(:result=).once

        subject.call
      end
    end

    context "when validations fail" do
      before do
        subject.any_instance.stubs(valid?: false)
        subject.any_instance.stubs(errors: [stub])
      end

      it "sets success? to false" do
        expect(subject.call.success?).to be false
      end

      it "does not call the instance level #__call" do
        subject.any_instance.expects(:__call).never

        subject.call
      end

      it "does not set instance.result" do
        expect(subject.call.result).to be nil
      end
    end

    it "returns the instance of the class" do
      instance = subject.new
      subject.stubs(new: instance)

      expect(subject.call).to eq instance
    end
  end
end
