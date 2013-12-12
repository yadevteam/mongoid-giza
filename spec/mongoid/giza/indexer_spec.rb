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
      allow(config).to receive(:render)
      expect(@controller).to receive(:index).with(:Person, :Person_2, verbose: true)
      @indexer.index!(:Person, :Person_2)
    end
  end

  describe "giza_classes" do
    before(:all) do
      class One
        include Mongoid::Document
        include Mongoid::Giza
      end

      class Two
        include Mongoid::Document
      end

      class Three
        include Mongoid::Document
        include Mongoid::Giza
      end
    end

    it "should return all classes that include the Giza module" do
      expect(@indexer.giza_classes).to include(One, Three)
    end

    it "should not return classes that do not include the Giza module" do
      expect(@indexer.giza_classes).not_to include(Two)
    end
  end
end
