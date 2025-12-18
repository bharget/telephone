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

    it "allows requiring an argument" do
      subject.public_send(:argument, :required_field, required: true)

      expect(subject.call.success?).to be false
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
