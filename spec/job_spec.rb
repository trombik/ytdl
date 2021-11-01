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

  describe "#valid_url?" do
    context "when url is http" do
      it "returns true" do
        expect(c.valid_url?("http://foo.example.org")).to be true
      end
    end

    context "when url is https" do
      it "returns true" do
        expect(c.valid_url?("https://foo.example.org")).to be true
      end
    end

    context "when url is empty" do
      it "returns false" do
        expect(c.valid_url?("")).to be false
      end
    end

    context "when url is not http" do
      it "returns false" do
        expect(c.valid_url?("ftp://foo.example.org")).to be false
      end
    end

    context "when url is file" do
      it "returns false" do
        expect(c.valid_url?("file:///etc/hosts")).to be false
      end
    end

    context "when url is nil" do
      it "returns false" do
        expect(c.valid_url?(nil)).to be false
      end
    end
  end

  describe ".validate" do
    let(:args) do
      {
        "extract-audio" => "",
        "audio-format" => "mp3",
        "url" => "http://foo.example.org"
      }
    end

    context "When valid args is given" do
      it "does not throw" do
        expect { c.validate(args) }.not_to raise_error
      end
    end
    context "When invalid args is given" do
      let(:invalid_args) do
        {
          "foo" => "bar",
          "url" => "http://foo.example.org"
        }
      end

      it "throws" do
        expect { c.validate(invalid_args) }.to raise_error ArgumentError
      end
    end
    context "when url is missing" do
      it "returns false" do
        args.delete("url")

        expect { c.validate(args) }.to raise_error ArgumentError
      end
    end

    context "when unknown audio-format is given" do
      it "throws" do
        args["audio-format"] = "exe"
        expect { c.validate(args) }.to raise_error ArgumentError
      end
    end

    context "when audio-format is empty string" do
      it "throws" do
        args["audio-format"] = ""

        expect { c.validate(args) }.to raise_error ArgumentError
      end
    end
  end
end
