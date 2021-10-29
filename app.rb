# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "sinatra"
require "sinatra/reloader"

configure do
  set public_dir: "assets"
end

get "/" do
  erb :index
end

get "/queues/?" do
  @queues = []
  erb :queues
end
