# frozen_string_literal: true

task default: %i[lint test]

task :test do
  sh "bundle exec rspec"
end

task :lint do
  sh "bundle exec standardrb --no-fix"
end
