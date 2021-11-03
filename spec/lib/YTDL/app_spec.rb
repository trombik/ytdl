# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../../lib/YTDL/app"
require "rack/test"
require "rspec-html-matchers"
require "rspec/json_expectations"

# set :environment, :test

RSpec::Matchers.define(:redirect_to) do |path|
  match do |response|
    uri = URI.parse(response.headers["Location"])
    response.status.to_s[0] == "3" && uri.path == path
  end
end

describe "Server Service" do
  include Rack::Test::Methods
  include RSpecHtmlMatchers

  before(:all) do
    @redis_pid = run_redis
    @worker_thr = run_worker
  end

  after(:all) do
    stop_redis(@redis_pid)
    stop_worker(@worker_thr)
  end

  before(:each) do
    # make the application instance available in examples so that one can mock
    # or stub methods. to mock or stub methods, use `@current_app`.
    #
    # for the issue, see:
    # http://www.philandstuff.com/2012/02/12/surprises-while-testing-sinatra-controllers.html
    # https://stackoverflow.com/questions/46114246/how-do-i-get-the-sinatra-app-instance-thats-being-tested-by-rack-test/46130697#46130697
    #
    # for a solution, see:
    # https://www.fraction.jp/log/archives/2013/12/06/stubbing-sinatra-helper
    # https://gist.github.com/yuanying/7818242#file-sinatra-helper-test-02-rb
    @current_app = app.helpers.dup
    allow(app.helpers).to receive(:dup).and_return(@current_app)
  end

  def app
    # @app ||= Sinatra::Application.new
    @app ||= YTDL::App.new
  end

  it "loads the home page" do
    get "/"
    expect(last_response).to be_ok
  end

  it "accepts a URL" do
    post "/", { url: "http://foo.example.com" }
    expect(last_response).to redirect_to "/"
    follow_redirect!
    expect(last_response.body).to have_tag(:div, text: /Queued/, with: { class: %w[alert alert-primary] })
  end

  context "when empty URL is given" do
    it "shows warning" do
      post "/", { url: "" }
      follow_redirect!
      expect(last_response.body).to have_tag(:div, text: /Failed to queue/, with: { class: %w[alert alert-warning] })
    end
  end

  context "when invalid URL is given" do
    invalids = %w[
      foo/bar/buz
      ftp://foo.exmple.org
      file:///etc/hosts
    ]
    invalids.each do |i|
      it "shows warning" do
        post "/", { url: i }
        follow_redirect!
        expect(last_response.body).to have_tag(:div, with: { class: %w[alert alert-warning] })
      end
    end
  end

  context "when valid URL is given" do
    valids = %w[
      http://foo.example.org
      https://foo.example.org
    ]
    valids.each do |i|
      it "does not shows warning" do
        post "/", { url: i }
        follow_redirect!
        expect(last_response.body).not_to have_tag(:div, with: { class: %w[alert alert-warning] })
      end
    end
  end

  context "when invalid audio format is given" do
    it "shows warning" do
      post "/", { url: "http://foo.example.org", "audio-format" => "foo" }
      follow_redirect!
      expect(last_response.body).to have_tag(:div, with: { class: %w[alert alert-warning] })
    end
  end

  context "when valid audio format is given" do
    it "shows warning" do
      post "/", { url: "http://foo.example.org", "audio-format" => "mp3" }
      follow_redirect!
      expect(last_response.body).not_to have_tag(:div, with: { class: %w[alert alert-warning] })
    end
  end

  it "loads the queue page" do
    get "/queues"
    expect(last_response).to be_ok
  end

  describe "/status" do
    it "shows status page" do
      get "/status"
      expect(last_response).to be_ok
    end
  end

  context "when submitting a job fails" do
    before(:each) do
      allow(@current_app).to receive(:async_download).and_raise(StandardError)
    end

    it "does not crash" do
      post "/", { url: "http://foo.example.com" }
      follow_redirect!
      expect(last_response.body).to have_tag(:div, text: /Failed to queue/, with: { class: %w[alert alert-warning] })
    end
  end

  describe "/api/v1" do
    describe "/hello_world" do
      it "returns hello_world" do
        get "/api/v1/hello_world"

        expect(last_response).to be_ok
        expect(last_response.body).to include_json({ "hello" => "world" })
      end
    end

    describe "/failed_jobs" do
      let(:failed_job) do
        { "failed_at" => "2021/11/01 13:09:42 +07",
          "payload" => { "class" => "YTDL::Job",
                         "args" => [{ "url" => "https://www.youtube.com/watch", "extract-audio" => "",
                                      "audio-format" => "mp3" }] },
          "exception" => "StandardError",
          "error" => "StandardError",
          "backtrace" =>
          ["/usr/home/trombik/github/trombik/ytdl/job.rb:55:in `block in download'",
           "/usr/local/lib/ruby/2.7/open3.rb:219:in `popen_run'",
           "/usr/local/lib/ruby/2.7/open3.rb:208:in `popen2e'",
           "/usr/home/trombik/github/trombik/ytdl/job.rb:49:in `download'",
           "/usr/home/trombik/github/trombik/ytdl/job.rb:43:in `perform'"],
          "worker" => "t480:18652:*",
          "queue" => "download" }
      end
      let(:resque_failure) { double("resque_failure") }

      it "returns failed jobs" do
        allow(@current_app).to receive(:resque_failure).and_return(resque_failure)
        allow(resque_failure).to receive(:all).and_return([failed_job, failed_job])

        get "/api/v1/failed_jobs"
        expect(last_response.body).to include_json(
          {
            "failed_jobs" => [failed_job, failed_job]
          }
        )
      end
    end

    describe "/jobs" do
      let(:job) do
        {
          "class" => "YTDL::Job",
          "args" => [
            {
              "url" => "https://www.youtube.com/watch?v=EOAPMhaCtuw",
              "extract-audio" => "",
              "audio-format" => "mp3"
            }
          ]
        }
      end
      let(:resque) { double("Resque") }

      it "returns array of jobs" do
        allow(@current_app).to receive(:resque).and_return(resque)
        allow(resque).to receive(:peek).and_return([job, job])

        get "/api/v1/jobs"
        expect(last_response.body).to include_json({ "jobs" => [job, job] })
      end

      context "When no job is found" do
        it "returns array of jobs" do
          allow(@current_app).to receive(:resque).and_return(resque)
          allow(resque).to receive(:peek).and_return([])

          get "/api/v1/jobs"
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

      it "creates a job" do
        post "/api/v1/job", job

        expect(last_response.body).to include_json(
          "result" => {
            "status" => "ok",
            "message" => "Queued https://www.youtube.com/watch?v=vNZOQiQHBaY"
          }
        )
      end

      context "when submitting a job failed" do
        it "returns failed result" do
          allow(@current_app).to receive(:async_download).and_raise(StandardError)
          post "/api/v1/job", job

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
          post "/api/v1/job", invalid_job

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
      let(:worker) { double("worker") }
      let(:worker_name) { "host:12345:*" }
      let(:resque_worker) { double("Resque::Worker") }
      let(:job) do
        {
          "queue" => "download",
          "run_at" => "2021-11-01T05:09:24Z",
          "payload" => {
            "class" => "YTDL::Job",
            "args" => [
              {
                "url" => "https://www.youtube.com/watch?v=vNZOQiQHBaY",
                "extract-audio" => "",
                "audio-format" => "mp3"
              }
            ]
          }
        }
      end

      before(:each) do
        allow(@current_app).to receive(:resque_worker).and_return(resque_worker)
        allow(worker).to receive(:job).and_return(job)
        allow(worker).to receive(:to_s).and_return(worker_name)
      end

      it "returns array of workers" do
        allow(@current_app).to receive(:workers).and_return([worker])

        get "/api/v1/workers"

        expect(last_response.body).to include_json(
          workers: [{ name: worker_name, job: job }]
        )
      end

      describe "/:id" do
        context "when existing worker name is given" do
          it "returns an worker" do
            allow(resque_worker).to receive(:find).and_return(worker)

            get "/api/v1/workers/#{worker_name}"

            expect(last_response.body).to include_json(
              { "name" => worker_name,
                "job" => job }
            )
          end
        end
        context "when non-existing worker name is given" do
          it "returns empty" do
            allow(resque_worker).to receive(:find).and_return(nil)

            get "/api/v1/workers/doesnotexist"

            expect(last_response.body).to include_json({})
          end
        end
      end
    end
  end
end
