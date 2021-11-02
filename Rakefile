# frozen_string_literal: true

require "resque"
require "resque/tasks"
require "shellwords"
require "redis"
require_relative "lib/YTDL/job"

ENV["YTDL_REDIS_ADDRESS"] ||= "127.0.0.1"
ENV["YTDL_REDIS_PORT"] ||= "16379"
ENV["YTDL_REDIS_DB_FILE"] ||= "test.rdb"

task default: [:test]

desc "Run tests"
task test: [:rspec, :rubocop]

desc "Run rspec"
task :rspec do
  redis_arg = "--bind #{ENV['YTDL_REDIS_ADDRESS'].shellescape} "
  redis_arg += "--port #{ENV['YTDL_REDIS_PORT'].shellescape} "
  redis_arg += "--logfile /dev/null "
  redis_arg += "--dbfilename #{ENV['YTDL_REDIS_DB_FILE'].shellescape}"
  redis_pid = spawn("redis-server #{redis_arg}")

  thr = Thread.new do
    ENV["QUEUE"] = "download"
    ENV["CI"] = "y"
    Resque.redis = "#{ENV['YTDL_REDIS_ADDRESS']}:#{ENV['YTDL_REDIS_PORT']}"
    worker = Resque::Worker.new
    worker.prepare
    worker.work(5)
  end

  sh "bundle exec rspec"

  Thread.kill(thr)
  Process.kill("TERM", redis_pid)
  Process.wait redis_pid
end

desc "Run rubocop"
task :rubocop do
  sh "bundle exec rubocop"
end
