require "spec_helper"

describe Mongoid::Giza::ID do
  describe "instance" do
    let(:giza_id) { Mongoid::Giza::ID.new(id: :Person) }

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

  describe "next" do
    before do
      Mongoid::Giza::ID.create(id: :Person)
    end

    it "should return the next id for the given class" do
      expect(Mongoid::Giza::ID.next(:Person)).to eql(1)
      expect(Mongoid::Giza::ID.next(:Person)).to eql(2)
    end
  end
end
