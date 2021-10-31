# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../job"

describe YTDL::Job do
  let(:c) { YTDL::Job }

  before(:each) do
    allow(c).to receive(:download).and_return true
  end

  describe ".perform" do
    it "performs a job" do
      args = {
        "extract-audio" => "",
        "url" => "http://foo.example.org",
        "audio-format" => "mp3"
      }
      expect { c.perform(args) }.not_to raise_error
    end
  end

  describe "#parse_args" do
    let(:args) do
      {
        "extract-audio" => "",
        "url" => "http://foo.example.org",
        "audio-format" => "mp3"
      }
    end

    it "parses args" do
      options = c.parse_args(args)
      expect(options).to include("--extract-audio")
      expect(options).to include("--audio-format", "mp3")
      expect(options.last).to be args["url"]
      expect(options).to include("--newline")
      expect(options).not_to include("")
    end

    context "When unknown options given" do
      it "raises error" do
        args["foo"] = true
        expect { c.parse_args(args) }.to raise_error ArgumentError
      end
    end

    context "When :url is missing" do
      it "raises error" do
        args.delete("url")
        expect { c.parse_args(args) }.to raise_error ArgumentError
      end
    end

    context "When unknown file format is given" do
      it "raises error" do
        args["audio-format"] = "exe"
        expect { c.parse_args(args) }.to raise_error ArgumentError
      end
    end
  end
end
