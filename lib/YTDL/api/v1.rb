# frozen_string_literal: true

require_relative "../base"
require_relative "../helpers"

class YTDL
  class API
    # API V1 application
    class V1 < YTDL::Base
      helpers do
        include YTDL::Helpers
      end

      before do
        content_type "application/json"
      end

      get "/version" do
        "0"
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
  end
end
