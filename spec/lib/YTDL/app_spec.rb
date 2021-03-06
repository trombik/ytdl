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

  it "has favicon" do
    get "/img/favicon-32x32.png"
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
end
