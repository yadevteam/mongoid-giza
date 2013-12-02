require "spec_helper"

describe Mongoid::Giza::Indexer do
  let(:indexer) { Mongoid::Giza::Indexer }

  let(:instance) { Mongoid::Giza::Instance }

  let(:config) { Mongoid::Giza::Configuration.instance }

  describe "index!" do
    it "should add all instance indexes to the configuration" do
      indexes = double("indexes")
      allow(config).to receive(:render)
      allow(instance).to receive(:indexes) { {a: 1, b: 2, c: 3} }
      expect(config).to receive(:add_index).with(1)
      expect(config).to receive(:add_index).with(2)
      expect(config).to receive(:add_index).with(3)
      indexer.index!
    end

    it "should create the sphinx configuration file" do
      allow(instance).to receive(:indexes) { {} }
      expect(config).to receive(:render)
      indexer.index!
    end

    it "should execute the sphinx indexer" do
      allow(instance).to receive(:indexes) { {} }
      allow(config).to receive(:render)
      expect(indexer.controller).to receive(:index)
      indexer.index!
    end
  end
end
