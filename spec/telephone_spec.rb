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
