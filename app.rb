# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "sinatra"
require "sinatra/reloader"
require "erubis"

require_relative "helpers"

set :erb, escape_html: true

configure do
  set public_dir: "assets"
  set :session_secret,
      "8f4e0fc3bc2a356718819c28c290529d9bc61fa886a2738bc416b204d6fbef2b7cc"
end

enable :sessions

helpers do
  include Helpers
end

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
