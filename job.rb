# frozen_string_literal: true

require "open3"

class YTDL
  # A job class to download a file
  class Job
    @queue = :download

    def self.perform(args)
      puts "args: #{args}"
      download(args)
      puts "Finished"
    end

    def self.download(args)
      cmd = ENV["CI"] ? "echo" : "youtube-dl"
      Open3.popen2e(cmd, *args) do |_stdin, out, wait_thr|
        puts "Waiting for #{wait_thr.pid}"
        code = wait_thr.value
        puts "exit status #{code}"
        puts out.read.to_s
        raise StandardError if code != 0
      end
    end
  end
end