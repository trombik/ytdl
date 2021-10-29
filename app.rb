# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "sinatra"
require "sinatra/reloader"
require "erubis"

set :erb, escape_html: true

configure do
  set public_dir: "assets"
  set :session_secret,
      "8f4e0fc3bc2a356718819c28c290529d9bc61fa886a2738bc416b204d6fbef2b7cc"
end

enable :sessions

get "/" do
  @message = session.delete(:message)
  @alert_message = session.delete(:alert_message)
  erb :index
end

post "/" do
  session[:url] = params[:url]
  if session[:url].empty?
    session[:alert_message] = "Empty URL"
  else
    session[:message] = "Queued #{session[:url]}"
  end
  redirect "/"
end

get "/queues/?" do
  @queues = []
  erb :queues
end
