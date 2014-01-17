# encoding: utf-8

require "spec_helper"

describe Mongoid::Giza::Index::Field do
  describe "name" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Index::Field.new }.to raise_error(ArgumentError)
    end

    it "should be set on creation" do
      name = :field
      field = Mongoid::Giza::Index::Field.new(name)
      expect(field.name).to eql(name)
    end

    it "should be converted to symbol" do
      name = "field"
      field = Mongoid::Giza::Index::Field.new(name)
      expect(field.name).to eql(name.to_sym)
    end

    it "should be downcased" do
      field = Mongoid::Giza::Index::Field.new("Field")
      expect(field.name).to eql(:field)
    end

    it "should downcase unicode chars" do
      field = Mongoid::Giza::Index::Field.new("ESPAÑOL")
      expect(field.name).to eql(:español)
    end

    it "should downcase symbols" do
      field = Mongoid::Giza::Index::Field.new(:Field)
      expect(field.name).to eql(:field)
    end

    it "should downcase unicode symbols" do
      field = Mongoid::Giza::Index::Field.new(:ESPAÑOL)
      expect(field.name).to eql(:español)
    end
  end

  it "should accept string attribute" do
    field = Mongoid::Giza::Index::Field.new("field", true)
    expect(field.attribute).to eql(true)
  end

  it "should accept a block" do
    field = Mongoid::Giza::Index::Field.new("field") { }
    expect(field.block).to be_a(Proc)
  end
end
