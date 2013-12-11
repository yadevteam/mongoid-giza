require "spec_helper"

describe Mongoid::Giza::GizaID do
  describe "instance" do
    let(:giza_id) { Mongoid::Giza::GizaID.new(id: :Person) }

    it "should be valid" do
      expect(giza_id).to be_valid
    end

    it "should have the specified id" do
      expect(giza_id.id).to eql(:Person)
    end

    it "should have a sequence default to zero" do
      expect(giza_id.seq).to eql(0)
    end
  end

  describe "next_id" do
    before do
      Mongoid::Giza::GizaID.create(id: :Person)
    end

    it "should return the next id for the given class" do
      expect(Mongoid::Giza::GizaID.next_id(:Person)).to eql(1)
      expect(Mongoid::Giza::GizaID.next_id(:Person)).to eql(2)
    end
  end
end
