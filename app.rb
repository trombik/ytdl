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

helpers do
  def valid_url?(string)
    uri = URI.parse(string)
    raise unless uri.scheme.match(/^https?$/)

    true
  rescue StandardError
    false
  end
end

get "/" do
  @message = session.delete(:message)
  @alert_message = session.delete(:alert_message)
  erb :index
end

post "/" do
  session[:url] = params[:url]
  if valid_url?(session[:url])
    session[:message] = "Queued #{session[:url]}"
  else
    session[:alert_message] = "Invalid URL"
  end
  redirect "/"
end

get "/queues/?" do
  @queues = []
  erb :queues
end
