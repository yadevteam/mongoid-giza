require "spec_helper"

describe Mongoid::Giza::DynamicIndex do
  describe "initialize" do
    it "should accept the class,  settings and a proc" do
      dynamic_index = Mongoid::Giza::DynamicIndex.new(Object, {}, Proc.new { })
      expect(dynamic_index.klass).to be(Object)
      expect(dynamic_index.settings).to eql({})
      expect(dynamic_index.block).to be_a_kind_of(Proc)
    end
  end

  describe "generate!" do
    let(:dynamic_index) { Mongoid::Giza::DynamicIndex.new(Object, {}, Proc.new { |object| name(object[:name]) }) }

    before do
      klass = double("class")
      index = double("index")
      allow(klass).to receive(:all) { [{name: "object"}, {name: "other"}, {name: "other"}] }
      allow(klass).to receive(:name) { :class }
      allow(dynamic_index).to receive(:klass) { klass }
    end

    it "should return a collection of indexes" do
      expect(dynamic_index.generate!).to be_a_kind_of(Hash)
    end

    it "should only return indexes with unique names" do
      expect(dynamic_index.generate!.length).to eql(2)
    end
  end
end
