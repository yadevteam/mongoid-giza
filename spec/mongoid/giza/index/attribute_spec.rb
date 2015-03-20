# encoding: utf-8

require "spec_helper"

describe Mongoid::Giza::Index::Attribute do
  describe "name" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Index::Attribute.new }
        .to raise_error(ArgumentError)
    end

    it "should be set on creation" do
      name = :attribute
      attribute = Mongoid::Giza::Index::Attribute.new(name, :int)
      expect(attribute.name).to eql(name)
    end

    it "should be converted to symbol" do
      name = "attribute"
      attribute = Mongoid::Giza::Index::Attribute.new(name, :int)
      expect(attribute.name).to eql(name.to_sym)
    end

    it "should be downcased" do
      attribute = Mongoid::Giza::Index::Attribute.new("Attribute", :int)
      expect(attribute.name).to eql(:attribute)
    end

    it "should downcase unicode chars" do
      attribute = Mongoid::Giza::Index::Attribute.new("ESPAÑOL", :int)
      expect(attribute.name).to eql(:español)
    end

    it "should downcase symbols" do
      attribute = Mongoid::Giza::Index::Attribute.new(:Attribute, :int)
      expect(attribute.name).to eql(:attribute)
    end

    it "should downcase unicode symbols" do
      attribute = Mongoid::Giza::Index::Attribute.new(:ESPAÑOL, :int)
      expect(attribute.name).to eql(:español)
    end
  end

  describe "type" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Index::Attribute.new("attribute") }
        .to raise_error(ArgumentError)
    end

    it "should be set on creation" do
      type = :int
      attribute = Mongoid::Giza::Index::Attribute.new("attribute", type)
      expect(attribute.type).to eql(type)
    end

    it "should be a valid type" do
      expect { Mongoid::Giza::Index::Attribute.new("attribute", :type) }
        .to raise_error(TypeError)
    end
  end

  it "should accept a block" do
    attribute = Mongoid::Giza::Index::Attribute.new("attribute", :int) {}
    expect(attribute.block).to be_a(Proc)
  end

  describe "options" do
    describe "default" do
      it "should accept default option" do
        attribute = Mongoid::Giza::Index::Attribute.new("attribute",
                                                        :int, default: 1)
        expect(attribute.default).to be 1
      end

      it "should be nil if not set" do
        attribute = Mongoid::Giza::Index::Attribute.new("attribute", :int)
        expect(attribute.default).to be nil
      end
    end

    describe "bits" do
      it "should accept bits option" do
        attribute = Mongoid::Giza::Index::Attribute.new("attribute",
                                                        :int, bits: 16)
        expect(attribute.bits).to be 16
      end

      it "should ignore if it's not an int attribute" do
        attribute = Mongoid::Giza::Index::Attribute.new("attribute",
                                                        :bool, bits: 16)
        expect(attribute.bits).to be nil
      end

      it "should be nil if not set" do
        attribute = Mongoid::Giza::Index::Attribute.new("attribute", :int)
        expect(attribute.bits).to be nil
      end
    end
  end
end
