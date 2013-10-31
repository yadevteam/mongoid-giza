require "spec_helper"

describe Mongoid::Giza::Instance do
  describe "indexes" do
    it "should store new indexes" do
      Mongoid::Giza::Instance.indexes[:index] = true
      expect(Mongoid::Giza::Instance.indexes.has_key?(:index)).to eql(true)
    end
  end
end
