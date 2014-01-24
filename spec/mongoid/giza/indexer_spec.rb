require "spec_helper"

describe Mongoid::Giza::Indexer do
  before do
    @controller = double("controller")
    allow(Riddle::Controller).to receive(:new) { @controller }
    @indexer = Mongoid::Giza::Indexer.send(:new)
  end

  let(:config) { Mongoid::Giza::Configuration.instance }

  describe "index!" do
    it "should execute the sphinx indexer" do
      allow(config).to receive(:render)
      expect(@controller).to receive(:index).with(no_args())
      @indexer.index!
    end

    it "should accept an index list" do
      allow(config).to receive(:render)
      expect(@controller).to receive(:index).with(:Person, :Person_2)
      @indexer.index!(:Person, :Person_2)
    end

    it "should accept verbose option" do
      expect(@controller).to receive(:index).with(verbose: true)
      @indexer.index!(verbose: true)
    end
  end

  describe "full_index!" do
    let(:klass) { double("class") }

    before do
      allow(@indexer).to receive(:index!)
      allow(config).to receive(:render)
    end

    it "should clear the generated indexes from the configuration" do
      expect(config).to receive(:clear_generated_indexes)
      allow(@indexer).to receive(:giza_classes) { [klass] }
      allow(klass).to receive(:regenerate_dynamic_sphinx_indexes)
      @indexer.full_index!
    end

    it "should regenerate all dynamic indexes of the giza classes" do
      allow(config).to receive(:clear_generated_indexes)
      allow(@indexer).to receive(:giza_classes) { [klass] }
      expect(klass).to receive(:regenerate_dynamic_sphinx_indexes)
      @indexer.full_index!
    end

    it "should create the sphinx configuration file" do
      allow(config).to receive(:clear_generated_indexes)
      allow(@indexer).to receive(:giza_classes) { [klass] }
      allow(klass).to receive(:regenerate_dynamic_sphinx_indexes)
      expect(config).to receive(:render)
      @indexer.full_index!
    end

    it "should execute the indexer" do
      allow(config).to receive(:clear_generated_indexes)
      allow(@indexer).to receive(:giza_classes) { [klass] }
      allow(klass).to receive(:regenerate_dynamic_sphinx_indexes)
      expect(@indexer).to receive(:index!).with(no_args)
      @indexer.full_index!
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
