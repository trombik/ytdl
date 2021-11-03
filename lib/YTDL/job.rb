# frozen_string_literal: true

require "open3"
require "uri"
require_relative "./config_loader"

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

    def self.log(str)
      puts str unless ENV["CI"]
    end

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
      return fake_download if ENV["CI"]

      log "args: #{args}"
      download(parse_args(args))
      log "Finished"
    end

    def self.fake_download
      sleep rand(3..5)
    end

    def self.cmd
      "youtube-dl"
    end

    def self.download(args)
      Dir.chdir(config["download_dir"]) do
        Open3.popen2e(cmd, *args) do |stdin, out, wait_thr|
          stdin.close
          log "Waiting for #{wait_thr.pid}"
          out.each { |line| log line }
          status = wait_thr.value
          log "exit status #{status}"
          raise StandardError unless status.success?
        end
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
      log "command line options: `#{@options.join(' ')}`"
      @options
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

    def self.config
      @config ||= ConfigLoader.new.load_file("config/YTDL.yml")
      @config
    end

    def initialize; end
  end
end
