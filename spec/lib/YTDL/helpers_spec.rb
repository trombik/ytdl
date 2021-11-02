# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../../lib/YTDL/helpers"

class TestHelpers
  include YTDL::Helpers
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
            params["extract-audio"] = ""
            params["audio-format"] = "mp3"

            expect(helpers.build_arg(params)).to include("audio-format" => "mp3")
            expect(helpers.build_arg(params)).to include("url" => params["url"])
          end
        end

        context "and invalid audio-format" do
          it "raises ArgumentError" do
            params["extract-audio"] = ""
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

      it "throw ArgumentError" do
        expect { helpers.valid_params?(params) }.to raise_error(ArgumentError)
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
            expect { helpers.valid_params?(params) }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
