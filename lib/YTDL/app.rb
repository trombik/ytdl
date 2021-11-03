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

class YTDL
  # The application
  class App < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
      after_reload do

        puts "reloaded"
      end
    end
    configure do
      config = YTDL::ConfigLoader.new.load_file("#{File.dirname(__FILE__)}/../../config/YTDL.yml")
      Resque.redis = "#{config['redis_address']}:#{config['redis_port']}"
    end

    register Sinatra::Namespace

    set :port, 5000
    set :sessions, true
    set :erb, escape_html: true
    set :static, true
    set :public_folder, Proc.new { File.join(root, "static") }
    set :session_secret,
        "8f4e0fc3bc2a356718819c28c290529d9bc61fa886a2738bc416b204d6fbef2b7cc"

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

    namespace "/api/v1" do
      helpers do
        include Helpers
      end

      before do
        content_type "application/json"
      end

      get "/hello_world" do
        res = { "hello" => "world" }
        res.to_json
      end

      get "/workers" do
        res = { workers: [] }
        workers.each do |worker|
          res[:workers] << {
            name: worker.to_s,
            job: worker.job
          }
        end
        res.to_json
      end

      get "/workers/:id" do |id|
        worker = resque_worker.find(id)
        if worker
          { name: worker.to_s,
            job: worker.job }.to_json
        else
          {}.to_json
        end
      end

      get "/jobs" do
        jobs = jobs("download", 0, 10)
        { "jobs" => jobs }.to_json
      end

      get "/failed_jobs" do
        jobs = resque_failure.all(0, 10)
        { "failed_jobs" => jobs }.to_json
      end

      post "/job" do
        result = {
          status: "fail",
          message: ""
        }
        begin
          valid_params?(params["args"])
          async_download(build_arg(params["args"]))
          result[:message] = "Queued #{params['args']['url']}"
          result[:status] = "ok"
        rescue StandardError => e
          result[:message] = "Failed to queue #{params['args']['url']}: #{e}"
        end
        status result[:message] == "ok" ? 200 : 400
        { result: result }.to_json
      end
    end
    run! if app_file == $PROGRAM_NAME
  end
end
