# frozen_string_literal: true

require_relative "lib/YTDL/app"
require_relative "lib/YTDL/api/v1"

map "/" do
  run YTDL::App
end

map "/api/v1" do
  run YTDL::API::V1
end
