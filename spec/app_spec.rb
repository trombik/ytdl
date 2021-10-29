# frozen_string_literal: true

require_relative "../app"
require "rspec"
require "rack/test"
require "rspec-html-matchers"

set :environment, :test

RSpec.configure do |config|
  config.include RSpecHtmlMatchers
end

RSpec::Matchers.define(:redirect_to) do |path|
  match do |response|
    uri = URI.parse(response.headers["Location"])
    response.status.to_s[0] == "3" && uri.path == path
  end
end

describe "Server Service" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "loads the home page" do
    get "/"
    expect(last_response).to be_ok
  end

  it "accepts a URL" do
    post "/", { url: "http://foo.example.com" }
    expect(last_response).to redirect_to "/"
  end

  context "when empty URL is given" do
    it "shows warning" do
      post "/", { url: "" }
      follow_redirect!
      expect(last_response.body).to have_tag(:div, with: { class: %w[alert alert-warning] })
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

  it "loads the queue page" do
    get "/queues"
    expect(last_response).to be_ok
  end
end
