require "spec_helper"

describe Mongoid::Giza::Index do
  let(:klass) { double("klass") }
  let(:index) { Mongoid::Giza::Index.new(klass) }

  it "should have a list of fields" do
    expect(index.fields).to be_a_kind_of(Array)
  end

  it "should have a list of attributes" do
    expect(index.attributes).to be_a_kind_of(Array)
  end

  describe "klass" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Index.new }.to raise_error(ArgumentError, "wrong number of arguments (0 for 1)")
    end

    it "should be set on creation" do
      expect(index.klass).to be(klass)
    end
  end

  describe "field" do
    let(:field) { double("field") }
    let(:name) { "field" }

    it "should require a name" do
      expect { index.field }.to raise_error(ArgumentError, "wrong number of arguments (0 for 1)")
    end

    it "should create a new Field" do
      expect(Mongoid::Giza::Field).to receive(:new).with(name, nil)
      index.field(name)
    end

    it "should accept a block" do
      expect(Mongoid::Giza::Field).to receive(:new).with(name, kind_of(Proc))
      index.field(name) { }
    end

    it "should add the new field to the list of fields" do
      allow(Mongoid::Giza::Field).to receive(:new) { field }
      index.field(name)
      expect(index.fields.first).to be(field)
    end
  end
end
