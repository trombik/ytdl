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
  # The base application for all
  class Base < Sinatra::Base
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

    set :sessions, true
    set :erb, escape_html: true
    set :static, true
    set :public_folder, (proc { File.join(root, "static") })
    set :session_secret,
        "8f4e0fc3bc2a356718819c28c290529d9bc61fa886a2738bc416b204d6fbef2b7cc"

    register Sinatra::Namespace
  end
end
