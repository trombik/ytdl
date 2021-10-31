# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../helpers"

class TestHelpers
  include Helpers
end

describe "App helpers" do
  let(:helpers) { TestHelpers.new }
  let(:resque) { double("Rescue") }

  describe "#workers" do
    let(:worker) { double("Worker") }
    it "returns workers" do
      allow(helpers).to receive(:resque).and_return(resque)
      allow(resque).to receive(:workers).and_return([worker, worker])

      expect(helpers.workers).to include(worker)
    end
  end

  describe "#build_arg" do
    context "when empty url is given" do
      it "raises ArgumentError" do
        expect { helpers.build_arg({ "url" => "" }) }.to raise_error(ArgumentError)
      end
    end

    context "when url is given" do
      let(:params) { { "url" => "http://foo.example.org" } }

      it "includes url as key" do
        expect(helpers.build_arg(params)).to include("url" => params["url"])
      end

      context "with extract-audio" do
        it "includes extract-audio" do
          params["extract-audio"] = ""

          expect(helpers.build_arg(params)).to include("extract-audio" => "")
          expect(helpers.build_arg(params)).to include("url" => params["url"])
        end

        context "and valid audio-format" do
          it "includes audio-format" do
            params["expect-audio"] = ""
            params["audio-format"] = "mp3"

            expect(helpers.build_arg(params)).to include("audio-format" => "mp3")
            expect(helpers.build_arg(params)).to include("url" => params["url"])
          end
        end

        context "and invalid audio-format" do
          it "raises ArgumentError" do
            params["expect-audio"] = ""
            params["audio-format"] = "exe"

            expect { helpers.build_arg(params) }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end

  describe "#valid_params?" do
    context "when invalid url is given" do
      let(:params) { { "url" => "ftp://foo.example.org" } }

      it "returms false" do
        expect(helpers.valid_params?(params)).to be false
      end
    end

    context "when valid url is given" do
      let(:params) { { "url" => "http://foo.example.org" } }

      it "returns true" do
        expect(helpers.valid_params?(params)).to be true
      end

      context "with extract-audio" do
        it "returns true" do
          params["extract-audio"] = ""
          expect(helpers.valid_params?(params)).to be true
        end

        context "and valid audio-format" do
          it " returns true" do
            params["extract-audio"] = ""
            params["audio-format"] = "mp3"
            expect(helpers.valid_params?(params)).to be true
          end
        end

        context "and invalid audio-format" do
          it " returns false" do
            params["extract-audio"] = ""
            params["audio-format"] = "foo"
            expect(helpers.valid_params?(params)).to be false
          end
        end
      end
    end
  end

  describe "#valid_url?" do
    context "when url is http" do
      it "returns true" do
        expect(helpers.valid_url?("http://foo.example.org")).to be true
      end
    end

    context "when url is https" do
      it "returns true" do
        expect(helpers.valid_url?("https://foo.example.org")).to be true
      end
    end

    context "when url is empty" do
      it "returns false" do
        expect(helpers.valid_url?("")).to be false
      end
    end

    context "when url is not http" do
      it "returns false" do
        expect(helpers.valid_url?("ftp://foo.example.org")).to be false
      end
    end

    context "when url is file" do
      it "returns false" do
        expect(helpers.valid_url?("file:///etc/hosts")).to be false
      end
    end

    context "when url is nil" do
      it "returns false" do
        expect(helpers.valid_url?(nil)).to be false
      end
    end

    context "when arg is array" do
      it "returns false" do
        expect(helpers.valid_url?([1, 2])).to be false
      end
    end

    context "when arg is hash" do
      it "returns false" do
        expect(helpers.valid_url?({ foo: :bar })).to be false
      end
    end
  end
end
