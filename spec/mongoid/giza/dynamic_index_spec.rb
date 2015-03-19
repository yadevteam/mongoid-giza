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
    let(:dynamic_index) { Mongoid::Giza::DynamicIndex.new(Object, {}, Proc.new { }) }

    let(:index) { double("index") }

    before do
      klass = double("class")
      allow(index).to receive(:name) { :name }
      allow(klass).to receive(:all) { Array.new(3) }
      allow(klass).to receive(:name) { :class }
      allow(dynamic_index).to receive(:klass) { klass }
      allow(dynamic_index).to receive(:generate_index) { index }
    end

    it "should generate index for each object of the class" do
      expect(dynamic_index).to receive(:generate_index).exactly(3).times
      dynamic_index.generate!
    end

    it "should return a collection of indexes" do
      expect(dynamic_index.generate!).to be_a_kind_of(Hash)
    end

    it "should only return indexes with unique names" do
      expect(dynamic_index.generate!.length).to eql(1)
    end

    it "should not an Index if it's nil" do
      allow(dynamic_index).to receive(:generate_index) { nil }
      expect(dynamic_index.generate!.length).to eql(0)
    end
  end

  describe "generate_index" do
    let(:index) { double("index") }

    before do
      allow(Mongoid::Giza::Index).to receive(:new) { index }
    end

    it "should check if the object is from the index's class" do
      expect(Mongoid::Giza::DynamicIndex.new(String, {}, -> {})
          .generate_index([])).to eql(nil)
    end

    it "should execute the index dsl on the parameter" do
      object = Object.new
      block = Proc.new { }
      expect(Docile).to receive(:dsl_eval).with(index, object, &block)
      Mongoid::Giza::DynamicIndex.new(Object, {}, block).generate_index(object)
    end

    it "should return an Index" do
      allow(Docile).to receive(:dsl_eval) { index }
      expect(Mongoid::Giza::DynamicIndex.new(String, {}, -> {})
        .generate_index("")).to be(index)
    end
  end
end
