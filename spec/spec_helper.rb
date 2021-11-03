# frozen_string_literal: true

require "rspec"

ENV["CI"] = "y"
ENV["RACK_ENV"] = "test"

def run_redis
  ENV["YTDL_REDIS_ADDRESS"] ||= "127.0.0.1"
  ENV["YTDL_REDIS_PORT"] ||= "16379"
  ENV["YTDL_REDIS_DB_FILE"] ||= "test.rdb"

  redis_arg = "--bind #{ENV['YTDL_REDIS_ADDRESS'].shellescape} " \
              "--port #{ENV['YTDL_REDIS_PORT'].shellescape} " \
              "--logfile /dev/null " \
              "--dbfilename #{ENV['YTDL_REDIS_DB_FILE'].shellescape}"
  redis_pid = spawn("redis-server #{redis_arg}")
  sleep 5

  Resque.redis = "#{ENV['YTDL_REDIS_ADDRESS']}:#{ENV['YTDL_REDIS_PORT']}"
  Resque.redis.redis.flushall
  redis_pid
end

def stop_redis(pid)
  Resque.redis.redis.flushall
  Process.kill("TERM", pid)
  Process.wait pid
end

def run_worker
  Thread.new do
    ENV["QUEUE"] = "download"
    ENV["CI"] = "y"
    Resque.redis = "#{ENV['YTDL_REDIS_ADDRESS']}:#{ENV['YTDL_REDIS_PORT']}"
    worker = Resque::Worker.new
    worker.prepare
    worker.work(5)
  end
end

def stop_worker(thr)
  Thread.kill(thr)
end
