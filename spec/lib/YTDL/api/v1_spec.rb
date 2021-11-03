# frozen_string_literal: true

require_relative "../../../spec_helper"
require_relative "../../../../lib/YTDL/api/v1"
require "rack/test"
require "rspec/json_expectations"

describe YTDL::API::V1 do
  include Rack::Test::Methods

  before(:all) do
    @redis_pid = run_redis
    @worker_thr = run_worker
  end

  after(:all) do
    stop_redis(@redis_pid)
    stop_worker(@worker_thr)
  end

  before(:each) do
    @current_app = app.helpers.dup
    allow(app.helpers).to receive(:dup).and_return(@current_app)
  end

  def app
    @app ||= YTDL::API::V1.new
  end

  it "loads the home page" do
    get "/version"
    expect(last_response).to be_ok
  end

  describe "/failed_jobs" do
    it "returns failed jobs" do
      get "/failed_jobs"

      expect(last_response).to be_ok
      expect(last_response.body).to include_json(
        {
          "failed_jobs" => []
        }
      )
    end
  end

  describe "/jobs" do
    context "When no job is found" do
      it "returns array of jobs" do
        get "/jobs"

        expect(last_response).to be_ok
        expect(last_response.body).to include_json({ "jobs" => [] })
      end
    end
  end

  describe "/job" do
    let(:job) do
      {
        "args" => {
          "url" => "https://www.youtube.com/watch?v=vNZOQiQHBaY",
          "extract-audio" => "",
          "audio-format" => "mp3"
        }
      }
    end

    let(:invalid_job) do
      {
        "args" => {
          "extract-audio" => "",
          "audio-format" => "mp3"
        }
      }
    end
    context "When a job is posted" do
      it "creates a job" do
        post "/job", job

        expect(last_response.body).to include_json(
          "result" => {
            "status" => "ok",
            "message" => "Queued https://www.youtube.com/watch?v=vNZOQiQHBaY"
          }
        )
      end
    end

    context "when submitting a job failed" do
      it "returns failed result" do
        allow(@current_app).to receive(:async_download).and_raise(StandardError)
        post "/job", job

        expect(last_response.body).to include_json(
          "result" => {
            "status" => "fail",
            "message" => /Failed to queue/
          }
        )
      end
    end
    context "when an invalid job is given" do
      it "returns failed result" do
        allow(@current_app).to receive(:async_download).and_raise(StandardError)
        post "/job", invalid_job

        expect(last_response.body).to include_json(
          "result" => {
            "status" => "fail",
            "message" => /Failed to queue/
          }
        )
      end
    end
  end

  describe "/workers" do
    it "returns array of workers" do
      get "/workers"

      expect(last_response.body).to include_json(
        workers: []
      )
    end

    describe "/:id" do
      context "when non-existing worker name is given" do
        it "returns empty" do
          get "/workers/doesnotexist"

          expect(last_response.body).to include_json({})
        end
      end
    end
  end
end
