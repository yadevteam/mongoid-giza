require "spec_helper"

describe Mongoid::Giza::Indexer do
  before do
    @controller = double("controller")
    allow(Riddle::Controller).to receive(:new) { @controller }
    @indexer = Mongoid::Giza::Indexer.send(:new)
  end

  let(:config) { Mongoid::Giza::Configuration.instance }

  describe "index!" do

    it "should create the sphinx configuration file" do
      allow(@controller).to receive(:index)
      expect(config).to receive(:render)
      @indexer.index!
    end

    it "should execute the sphinx indexer" do
      allow(config).to receive(:render)
      expect(@controller).to receive(:index).with(verbose: true)
      @indexer.index!
    end

    it "should accept an index list" do
      person = double("person")
      person_2 = double("person 2")
      allow(person).to receive(:name) { :Person }
      allow(person_2).to receive(:name) { :Person_2 }
      allow(config).to receive(:render)
      expect(@controller).to receive(:index).with(:Person, :Person_2, verbose: true)
      @indexer.index!(person, person_2)
    end
  end
end
