require "spec_helper"

describe Mongoid::Giza::Field do
  describe "name" do
    it "should be mandatory" do
      expect { Mongoid::Giza::Field.new }.to raise_error(ArgumentError, "wrong number of arguments (0 for 1)")
    end

    it "should be set on creation" do
      name = "field"
      field = Mongoid::Giza::Field.new(name)
      expect(field.name).to eql(name)
    end
  end

  it "should accept a block" do
    field = Mongoid::Giza::Field.new("field") { }
    expect(field.block).to be_a(Proc)
  end
end
