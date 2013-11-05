require "spec_helper"

describe Mongoid::Giza::Index::Field do
  describe "name" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Index::Field.new }.to raise_error(ArgumentError)
    end

    it "should be set on creation" do
      name = "field"
      field = Mongoid::Giza::Index::Field.new(name)
      expect(field.name).to eql(name)
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
