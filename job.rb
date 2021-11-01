# frozen_string_literal: true

require "open3"
require "uri"

class YTDL
  # A job class to download a file
  class Job
    @queue = :download

    VALID_ARGS = %w[
      extract-audio
      audio-format
      url
    ].freeze
    AUDIO_FORMATS = %w[best aac flac mp3 m4a vorbis].freeze

    def self.valid_url?(string)
      uri = URI.parse(string)
      raise unless uri.scheme.match(/^https?$/)

      true
    rescue StandardError
      false
    end

    def self.validate(args)
      raise ArgumentError, "missing url" unless args.key?("url")
      raise ArgumentError, "invalid url" unless valid_url?(args["url"])

      args.each_key do |k|
        raise ArgumentError, "invalid key #{k}" unless VALID_ARGS.include?(k)
      end
      if args.key?("audio-format") && !AUDIO_FORMATS.include?(args["audio-format"])
        raise ArgumentError,
              "unknown audio-format"
      end

      true
    end

    def self.perform(args)
      puts "args: #{args}"
      download(parse_args(args))
      puts "Finished"
    end

    def self.download(args)
      cmd = "youtube-dl"
      Open3.popen2e(cmd, *args) do |stdin, out, wait_thr|
        stdin.close
        puts "Waiting for #{wait_thr.pid}"
        out.each { |line| puts line }
        status = wait_thr.value
        puts "exit status #{status}"
        raise StandardError unless status.success?
      end
    end

    def self.parse_args(args)
      valid_args?(args)
      @options = []
      args.keys.reject { |k| k == "url" }.each do |k|
        @options << "--#{k}"
        @options << args[k]
      end
      @options << "--newline" << args["url"]
      @options.reject! { |i| i == "" }
    end

    def self.valid_args?(args)
      raise ArgumentError, "missing url" unless args.key?("url")

      if args.key?("audio-format") && !AUDIO_FORMATS.include?(args["audio-format"])
        raise ArgumentError,
              "invalid file format"
      end

      args.each_key do |k|
        raise ArgumentError, "unknown option `#{k}`" unless VALID_ARGS.include?(k)
      end
    end

    def initialize; end
  end
end
