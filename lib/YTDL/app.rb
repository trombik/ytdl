# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "sinatra/reloader"
require "sinatra/namespace"
require "erubis"

require_relative "helpers"
require_relative "job"
require_relative "config_loader"
require_relative "base"
require_relative "api/v1"

class YTDL
  # The application
  class App < YTDL::Base
    helpers YTDL::Helpers

    get "/" do
      @message = session.delete(:message)
      @alert_message = session.delete(:alert_message)
      @audio_formats = YTDL::Job::AUDIO_FORMATS
      erb :index
    end

    post "/" do
      # logger.info params
      begin
        valid_params?(params)
        async_download(build_arg(params))
        session[:message] = "Queued #{session[:url]}"
      rescue StandardError => e
        session[:alert_message] = "Failed to queue #{session[:url]}: #{e}"
      end
      redirect "/"
    end

    get "/queues" do
      erb :queues
    end

    get "/status/?" do
      @jobs = jobs("download", 0, 10)
      @workers = workers
      @resque_failure = resque_failure
      erb :status
    end
  end
end
