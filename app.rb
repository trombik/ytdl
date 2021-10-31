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
  @audio_formats = valid_audio_formats
  erb :index
end

post "/" do
  # logger.info params
  if valid_params?(params)
    begin
      async_download(build_arg(params))
      session[:message] = "Queued #{session[:url]}"
    rescue StandardError
      session[:alert_message] = "Failed to queue #{session[:url]}"
    end
  else
    session[:alert_message] = "Invalid parameters"
  end
  redirect "/"
end

get "/queues" do
  erb :queues
end

get "/status/?" do
  @jobs = jobs("download", 0, 10)
  @workers = workers
  erb :status
end
