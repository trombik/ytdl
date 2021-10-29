# frozen_string_literal: true

desc "Run tests"
task test: [:rspec, :rubocop]

desc "Run rspec"
task :rspec do
  sh "bundle exec rspec"
end

desc "Run rubocop"
task :rubocop do
  sh "bundle exec rubocop"
end
