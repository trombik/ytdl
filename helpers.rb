# frozen_string_literal: true

require "uri"
require "resque"
require_relative "job"

# Helper methods for App
module Helpers
  def valid_params?(params)
    YTDL::Job.validate(params)
  end

  def async_download(args)
    resque.enqueue(YTDL::Job, args)
  rescue Object => e
    logger.err "failed to enqueue job: #{args}"
    logger.err e.backtrace
    raise e
  end

  def build_arg(params)
    valid_params?(params)
    params
  end

  def resque
    Resque
  end

  def resque_worker
    Resque::Worker
  end

  def jobs(queue, start, count)
    jobs = []
    resque.peek(queue, start, count).each do |job|
      jobs << job
    end
    jobs
  end

  def workers
    resque.workers
  end

  def resque_failure
    Resque::Failure
  end
end
