require "rake"
require "fileutils"
require "tmpdir"

RSpec.describe "telephone:migrate rake task" do
  let(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  def run_migrate(path = tmpdir)
    load File.expand_path("../lib/telephone/tasks/migrate.rake", __dir__)
    Rake::Task["telephone:migrate"].reenable
    Rake::Task["telephone:migrate"].invoke(path)
  end

  it "adds validates: { presence: true } to required: true arguments" do
    File.write("#{tmpdir}/example_service.rb", <<~RUBY)
      class ExampleService < Telephone::Service
        argument :user, required: true
        argument :name, default: "test"

        def call
          user
        end
      end
    RUBY

    run_migrate

    content = File.read("#{tmpdir}/example_service.rb")
    expect(content).to include("argument :user, required: true, validates: { presence: true }")
    expect(content).to include('argument :name, default: "test"')
  end

  it "handles required: true with other options" do
    File.write("#{tmpdir}/multi_option_service.rb", <<~RUBY)
      class MultiOptionService < Telephone::Service
        argument :email, required: true, default: nil
      end
    RUBY

    run_migrate

    content = File.read("#{tmpdir}/multi_option_service.rb")
    expect(content).to include("required: true, validates: { presence: true }")
  end

  it "does not modify arguments that already have validates:" do
    original = <<~RUBY
      class AlreadyMigratedService < Telephone::Service
        argument :email, required: true, validates: { format: { with: /@/ } }
      end
    RUBY

    File.write("#{tmpdir}/already_migrated_service.rb", original)

    run_migrate

    content = File.read("#{tmpdir}/already_migrated_service.rb")
    expect(content).to eq(original)
  end

  it "does not modify arguments without required: true" do
    original = <<~RUBY
      class NoRequiredService < Telephone::Service
        argument :name, default: "test"
        argument :optional
      end
    RUBY

    File.write("#{tmpdir}/no_required_service.rb", original)

    run_migrate

    content = File.read("#{tmpdir}/no_required_service.rb")
    expect(content).to eq(original)
  end

  it "handles multiple required arguments in the same file" do
    File.write("#{tmpdir}/multiple_required_service.rb", <<~RUBY)
      class MultipleRequiredService < Telephone::Service
        argument :user, required: true
        argument :account, required: true
        argument :optional_thing
      end
    RUBY

    run_migrate

    content = File.read("#{tmpdir}/multiple_required_service.rb")
    expect(content).to include("argument :user, required: true, validates: { presence: true }")
    expect(content).to include("argument :account, required: true, validates: { presence: true }")
    expect(content).to include("argument :optional_thing")
    expect(content).not_to include("optional_thing, required")
  end

  it "preserves indentation" do
    File.write("#{tmpdir}/indented_service.rb", <<~RUBY)
      module Foo
        class IndentedService < Telephone::Service
          argument :user, required: true

          def call
            user
          end
        end
      end
    RUBY

    run_migrate

    content = File.read("#{tmpdir}/indented_service.rb")
    expect(content).to include("    argument :user, required: true, validates: { presence: true }")
  end
end
