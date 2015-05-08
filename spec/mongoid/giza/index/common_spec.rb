# encoding: utf-8

require "spec_helper"

describe Mongoid::Giza::Index::Common do
  include Mongoid::Giza::Index::Common

  describe "normalize" do
    it "should replace non-alphabetic characters with a dash" do
      expect(normalize("aá(")).to eql(:"aá-")
    end
  end
end
