# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../../lib/YTDL/config_loader"

describe YTDL::ConfigLoader do
  let(:valid_erb) do
    <<-YAML
    redis_address: 127.0.0.1
    redis_port: 6379
    download_dir: <%= "/tmp" %>
    YAML
  end

  let(:invalid_erb) do
    <<-YAML
    foo: bar
    buz: yes
    YAML
  end

  let(:obj) { YTDL::ConfigLoader.new }

  describe "#new" do
    it "creates object" do
      expect { YTDL::ConfigLoader.new }.not_to raise_error
    end
  end

  describe "#read_erb" do
    it "parse arg as erb" do
      allow(obj).to receive(:read_file).and_return(valid_erb)
      expect { obj.read_erb("/foo/bar") }.not_to raise_error
    end
  end

  describe "#read_yaml" do
    it "parse arg as YAML" do
      result = ""
      expect do
        result = obj.read_erb(valid_erb)
        obj.read_yaml(result)
      end.not_to raise_error
    end

    context "When content is empty" do
      it "does not raise" do
        expect { obj.read_yaml("") }.to raise_error ArgumentError
      end
    end
  end

  describe "#required_keys" do
    it "includes download_dir" do
      expect(obj.required_keys).to include("download_dir")
    end
  end
  describe "#validate_missing_key" do
    context "When required key is missing" do
      it "raises ArgumentError" do
        expect { obj.validate_missing_key({ foo: "bar" }) }.to raise_error ArgumentError
      end
    end
  end

  describe "#validate_unknown_key" do
    context "When unknown key is found" do
      it "raises ArgumentError" do
        expect { obj.validate_unknown_key({ foo: "bar" }) }.to raise_error ArgumentError
      end
    end
  end

  describe "#validate_type" do
    context "When Integer is expected but Srting is given" do
      it "raises ArgumentError" do
        expect { obj.validate_type({ "redis_port" => "5000" }) }.to raise_error ArgumentError
      end
    end
  end

  describe "#validate" do
    context "when valid config is given" do
      it "does not raise" do
        expect do
          obj.validate({ "download_dir" => "/tmp" })
        end.not_to raise_error
      end
    end
    context "when invalid config is given" do
      it "raises" do
        result = ""
        expect do
          result = obj.read_erb(invalid_erb)
          result = obj.read_yaml(result)
          result = obj.validate(result)
        end.to raise_error ArgumentError
      end
    end
  end

  describe "#merge_default" do
    context "When optional key is missing" do
      it "merge DEFAULT_OPTION" do
        result = obj.merge_default({ "redis_address" => "foo.example.org" })
        expect(result["redis_address"]).to eq "foo.example.org"
        expect(result["redis_port"]).to eq 6379
      end
    end
  end

  describe "#override_with_env" do
    context "when same key with YTDL_ prefix is set in environment" do
      before(:each) { ENV["YTDL_REDIS_PORT"] = "16379" }
      after(:each) { ENV.delete("YTDL_REDIS_PORT") }

      it "overrides the key in the config" do
        result = obj.override_with_env({ "redis_port" => 6379 })
        expect(result["redis_port"]).to eq 16_379
      end
    end
  end

  describe "#load_file" do
    it "loads file and returns config" do
      allow(obj).to receive(:read_file).and_return(valid_erb)
      result = obj.load_file("/foo/bar")
      expect(result).to include("redis_address" => "127.0.0.1")
      expect(result).to include("redis_port" => 6379)
      expect(result).to include("download_dir" => "/tmp")
    end

    context "When invalid key is given" do
      it "raises ArgumentError" do
        content = <<-CONFIG
        download_dir: /tmp
        foo: bar
        CONFIG
        allow(obj).to receive(:read_file).and_return(content)
        expect { obj.load_file("/foo/bar") }.to raise_error ArgumentError
      end
    end

    context "When required key is missing" do
      it "raises ArgumentError" do
        expect(obj).to receive(:read_file).and_return("port: 5000")
        expect { obj.load_file("/foo/bar") }.to raise_error ArgumentError
      end
    end

    context "When redis_port is overriden by YTDL_REDIS_PORT" do
      before(:each) { ENV["YTDL_REDIS_PORT"] = "16379" }
      after(:each) { ENV.delete("YTDL_REDIS_PORT") }

      it "returns config with YTDL_REDIS_PORT" do
        expect(obj).to receive(:read_file).and_return("download_dir: /tmp")
        result = obj.load_file("/foo/bar")
        expect(result["redis_port"]).to be 16_379
      end
    end

    context "When redis_port is overriden by YTDL_REDIS_PORT but the value is String" do
      before(:each) { ENV["YTDL_REDIS_PORT"] = "foo" }
      after(:each) { ENV.delete("YTDL_REDIS_PORT") }

      it "raises ArgumentError" do
        allow(obj).to receive(:read_file).and_return("download_dir: /tmp")

        expect { obj.load_file("/foo/bar") }.to raise_error ArgumentError
      end
    end

    context "When redis_address is overriden by YTDL_REDIS_ADDRESS" do
      before(:each) { ENV["YTDL_REDIS_ADDRESS"] = "127.0.0.1" }
      after(:each) { ENV.delete("YTDL_REDIS_ADDRESS") }

      it "does not raise" do
        allow(obj).to receive(:read_file).and_return("download_dir: /tmp")

        expect { obj.load_file("/foo/bar") }.not_to raise_error
      end
    end
  end
end
