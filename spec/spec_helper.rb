# frozen_string_literal: true

require "rspec"
require "shellwords"

ENV["CI"] = "y"
ENV["RACK_ENV"] = "test"

def load_config
  require_relative "../lib/YTDL/config_loader"
  YTDL::ConfigLoader.new.load_file("#{File.dirname(__FILE__)}/../config/YTDL.yml")
end

def run_redis
  config = load_config
  redis_arg = "--bind #{config['redis_address'].shellescape} " \
              "--port #{config['redis_port'].to_s.shellescape} " \
              "--logfile /dev/null " \
              "--dbfilename #{config['redis_dbfilename'].shellescape}"
  redis_pid = spawn("redis-server #{redis_arg}")
  sleep 2

  Resque.redis = "#{config['redis_address']}:#{config['redis_port']}"
  Resque.redis.redis.flushall
  redis_pid
end

def stop_redis(pid)
  Resque.redis.redis.flushall
  Process.kill("TERM", pid)
  Process.wait pid
end

def run_worker
  config = load_config
  Thread.new do
    ENV["QUEUE"] = "download"
    ENV["CI"] = "y"
    Resque.redis = "#{config['redis_address']}:#{config['redis_port']}"
    worker = Resque::Worker.new
    worker.prepare
    worker.work(5)
  end
end

def stop_worker(thr)
  Thread.kill(thr)
end
