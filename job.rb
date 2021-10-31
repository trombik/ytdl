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
  end
end
