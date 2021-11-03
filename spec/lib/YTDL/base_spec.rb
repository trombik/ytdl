# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../../lib/YTDL/base"

describe YTDL::Base do
  describe "#new" do
    it "does not raise" do
      expect { YTDL::Base.new }.not_to raise_error
    end
  end
end
