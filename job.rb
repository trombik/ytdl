# frozen_string_literal: true

require "open3"

class YTDL
  # A job class to download a file
  class Job
    @queue = :download

    KNOWN_OPTIONS = %w[
      extract-audio
      audio-format
      url
    ].freeze
    VALID_AUDIO_FORMATS = %w[best aac flac mp3 m4a vorbis].freeze

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
        puts "exit status #{code}"
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

      if args.key?("audio-format") && !VALID_AUDIO_FORMATS.include?(args["audio-format"])
        raise ArgumentError,
              "invalid file format"
      end

      args.each_key do |k|
        raise ArgumentError, "unknown option `#{k}`" unless KNOWN_OPTIONS.include?(k)
      end
    end

    def initialize; end
  end
end
