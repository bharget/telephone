# frozen_string_literal: true

require_relative "lib/telephone/version"

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "telephone"
  s.version = Telephone::VERSION
  s.authors = ["Benjamin Hargett"]
  s.email = "hargettbenjamin@gmail.com"
  s.summary = "Utility class for creating and calling service objects."
  s.description = s.summary
  s.homepage = "https://github.com/bharget/telephone"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/bharget/telephone/issues",
    "changelog_uri" => "https://github.com/bharget/telephone/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/bharget/telephone"
  }

  s.required_ruby_version = ">= 3.2.0"

  s.files = Dir["README.md", "lib/**/*"]
  s.require_paths = ["lib"]
  s.requirements << "none"

  s.add_dependency "activemodel"
end
