# frozen_string_literal: true

require_relative "lib/YTDL/app"

map "/" do
  run YTDL::App
end

map "/api/v1" do
  run YTDL::API::V1
end
