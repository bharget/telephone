# frozen_string_literal: true

require "bundler/gem_tasks"

task default: %i[lint test]

task :test do
  sh "bundle exec rspec"
end

task :lint do
  sh "bundle exec standardrb --no-fix"
end

namespace :changelog do
  task :refresh do
    sh "bin/refresh_changelog"
  end
end
