require "spec_helper"

describe Mongoid::Giza::Instance do
  let(:instance) { Mongoid::Giza::Instance }

  describe "indexes" do
    it "should store new indexes" do
      instance.indexes[:index] = true
      expect(instance.indexes.has_key?(:index)).to eql(true)
    end
  end
end
