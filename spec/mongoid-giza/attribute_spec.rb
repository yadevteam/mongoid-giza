require "spec_helper"

describe Mongoid::Giza::Attribute do
  describe "name" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Attribute.new }.to raise_error(ArgumentError, "wrong number of arguments (0 for 2)")
    end

    it "should be set on creation" do
      name = "attribute"
      attribute = Mongoid::Giza::Attribute.new(name, :uint)
      expect(attribute.name).to eql(name)
    end
  end

  describe "type" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Attribute.new("attribute") }.to raise_error(ArgumentError, "wrong number of arguments (1 for 2)")
    end

    it "should be set on creation" do
      type = :uint
      attribute = Mongoid::Giza::Attribute.new("attribute", type)
      expect(attribute.type).to eql(type)
    end

    it "should be a valid type" do
      expect { Mongoid::Giza::Attribute.new("attribute", :type) }.to raise_error(TypeError)
    end
  end

  it "should accept a block" do
    attribute = Mongoid::Giza::Attribute.new("attribute", :uint) { }
    expect(attribute.block).to be_a(Proc)
  end
end
