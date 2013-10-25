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

  describe "attribute" do
    let(:name) { "attribute" }
    let(:type) { :uint }

    it "should require a name" do
      expect { index.attribute }.to raise_error(ArgumentError, "wrong number of arguments (0 for 1..2)")
    end

    it "should accept a type" do
      expect(Mongoid::Giza::Attribute).to receive(:new).with(name, type, nil)
      index.attribute(name, type)
    end

    it "should accept a block" do
      expect(Mongoid::Giza::Attribute).to receive(:new).with(name, type, kind_of(Proc))
      index.attribute(name, type) { }
    end

    it "should automatically define the type when it is not supplied" do
      type = String
      allow(klass).to receive(:fields) do
        fields = double("fields")
        allow(fields).to receive(:[]).with(name) do
          field = double("field")
          allow(field).to receive(:type) { type }
          field
        end
        fields
      end
      expect(Mongoid::Giza::Attribute).to receive(:new).with(name, index.class.types_map[type], nil)
      index.attribute(name)
    end

    it "should default to the first type when the field is not found" do
      allow(klass).to receive(:fields) do
        fields = double("fields")
        allow(fields).to receive(:[]).with(name) { nil }
        fields
      end
      expect(Mongoid::Giza::Attribute).to receive(:new).with(name, index.class.types_map.values.first, nil)
      index.attribute(name)
    end

    it "should default to the first type when the type is not mapped" do
      allow(klass).to receive(:fields) do
        fields = double("fields")
        allow(fields).to receive(:[]).with(name) do
          field = double("field")
          allow(field).to receive(:type) { Object }
          field
        end
        fields
      end
      expect(Mongoid::Giza::Attribute).to receive(:new).with(name, index.class.types_map.values.first, nil)
      index.attribute(name)
    end
  end
end
