# frozen_string_literal: true

require "uri"
require "resque"
require_relative "job"

VALID_AUDIO_FORMATS = %w[best aac flac mp3 m4a vorbis].freeze

# Helper methods for App
module Helpers
  def valid_url?(string)
    uri = URI.parse(string)
    raise unless uri.scheme.match(/^https?$/)

    true
  rescue StandardError
    false
  end

  def valid_params?(params)
    raise if params.key?("audio-format") && !valid_audio_formats.include?(params["audio-format"])
    raise unless valid_url?(params["url"])

    true
  rescue StandardError
    false
  end

  def async_download(args)
    return if ENV["CI"]

    Resque.enqueue(YTDL::Job, args)
  end

  def build_arg(params)
    args = []
    raise ArgumentError unless valid_params?(params)

    args << "--extract-audio" if params.key?("extract-audio")
    args << "--audio-format" << params["audio-format"] if params.key?("audio-format")
    args << "--newline"
    args << params["url"]
  end

  def valid_audio_formats
    VALID_AUDIO_FORMATS
  end

  def resque
    Resque
  end

  def jobs(queue, start, count)
    jobs = []
    resque.peek(queue, start, count).each do |job|
      jobs << job["args"].first.last
    end
    jobs
  end

  def workers
    resque.workers
  end
end
