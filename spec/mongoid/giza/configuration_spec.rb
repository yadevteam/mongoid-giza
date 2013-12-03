require "spec_helper"

describe Mongoid::Giza::Configuration do
  before do
    @default_source = double("default_source")
    @default_index = double("default_index")
    allow(Riddle::Configuration::XMLSource).to receive(:new).with(:source, :xmlpipe2) { @default_source }
    allow(Riddle::Configuration::Index).to receive(:new).with(:index, @default_source) { @default_index }
    @config = Mongoid::Giza::Configuration.send(:new)
  end

  describe "initialize" do
    it "should create a Riddle::Configuration::Index for default settings" do
      expect(@config.index).to be(@default_index)
    end

    it "should create a Riddle::Configuration::XMLSource for default settings" do
      expect(@config.source).to be(@default_source)
    end

    describe "file section" do
      it "should create a file section" do
        expect(@config.file).to be_a_kind_of(OpenStruct)
      end

      it "should have output path setting" do
        expect(@config.file.respond_to?(:output_path=)).to be(true)
      end
    end
  end

  describe "load" do
    let(:file) { double("file") }

    let(:file_open) { allow(File).to receive(:open).with("giza.yml") { file } }

    it "should load the configuration file" do
      expect(file).to receive(:read) { "test:\n  searchd:\n    address: localhost" }
      expect(File).to receive(:open).with("giza.yml") { file }
      @config.load("giza.yml", "test")
    end

    it "should set settings" do
      allow(file).to receive(:read) { "test:\n  searchd:\n    address: localhost" }
      file_open
      @config.load("giza.yml", "test")
      expect(@config.searchd.address).to eql("localhost")
    end

    it "should ignore non-existent sections" do
      allow(file).to receive(:read) { "test:\n  miss_section:\n    address: localhost" }
      file_open
      expect { @config.load("giza.yml", "test") }.not_to raise_error
    end

    it "should ignore non-existent settings" do
      allow(file).to receive(:read) { "test:\n  searchd:\n    miss_setting: false" }
      expect(@config.searchd).not_to receive(:method_missing).with(:miss_setting=, false)
      file_open
      @config.load("giza.yml", "test")
    end
  end

  describe "add_index" do
    let(:index) do
      index = double("index")
      allow(index).to receive(:name) { :Person }
      allow(index).to receive(:settings) { Hash.new }
      index
    end

    let(:riddle_index) { double("riddle_index").as_null_object }

    let(:source) { double("source").as_null_object }

    before do
      allow(Riddle::Configuration::Index).to receive(:settings) { [] }
      allow(Riddle::Configuration::XMLSource).to receive(:new) { source }
      allow(Riddle::Configuration::Index).to receive(:new).with(index.name, source) { riddle_index }
      allow(@config).to receive(:apply_settings)
    end

    it "should add an Riddle::Configuration::Index" do
      allow(Riddle::Configuration::Index).to receive(:new) { double("riddle_index").as_null_object }
      expect { @config.add_index(index) }.to change{@config.indices.length}.by(1)
    end

    it "should create a xmlpipe2 source with the same name of the index" do
      expect(Riddle::Configuration::XMLSource).to receive(:new).with(index.name, :xmlpipe2) { source }
      allow(Riddle::Configuration::Index).to receive(:new) { double("riddle_index").as_null_object }
      @config.add_index(index)
    end

    it "should set the path" do
      allow(Riddle::Configuration::Index).to receive(:settings) { [:path] }
      allow(@default_index).to receive(:path) { "/path/to/index" }
      allow(riddle_index).to receive(:path=).with("/path/to/index")
      allow(riddle_index).to receive(:path) { "/path/to/index" }
      expect(riddle_index).to receive(:path=).with("/path/to/index/#{index.name}")
      @config.add_index(index)
    end

    it "should not add the same index twice" do
      allow(Riddle::Configuration::Index).to receive(:new) { double("riddle_index").as_null_object }
      @config.add_index(index)
      expect { @config.add_index(index) }.not_to change{@config.indices.length}.by(1)
    end

    it "should apply global settings to the index" do
      expect(@config).to receive(:apply_settings).with(@default_index, riddle_index)
      @config.add_index(index)
    end

    it "should apply global settings to the source" do
      expect(@config).to receive(:apply_settings).with(@default_source, source)
      @config.add_index(index)
    end

    it "should apply user defined settings to the index" do
      expect(@config).to receive(:apply_settings).with(index, riddle_index)
      @config.add_index(index)
    end

    it "should apply user defined settings to the source" do
      expect(@config).to receive(:apply_settings).with(index, source)
      @config.add_index(index)
    end
  end

  describe "apply_settings" do
    before do
      @section = double("section")
      @instance = double("instance")
      allow(@section).to receive(:settings) { [:html_strip] }
    end

    it "should apply the settings from section to instance" do
      allow(@section).to receive(:html_strip) { 1 }
      allow(@instance).to receive(:respond_to?).with("html_strip=") { true }
      expect(@instance).to receive(:html_strip=).with(1)
      @config.apply_settings(@section, @instance)
    end

    it "should not set nil values" do
      allow(@section).to receive(:html_strip) { nil }
      allow(@instance).to receive(:respond_to?).with("html_strip=") { true }
      expect(@instance).not_to receive(:html_strip=)
      @config.apply_settings(@section, @instance)
    end

    it "should not try to apply settings without a setter" do
      allow(@section).to receive(:html_strip) { 1 }
      allow(@instance).to receive(:respond_to?).with("html_strip=") { false }
      expect(@instance).not_to receive(:html_strip=)
      @config.apply_settings(@section, @instance)
    end
  end

  describe "render" do
    it "should render the configuration to the specified output path" do
      file = double("file")
      index = double("index")
      @config.indices << index
      allow(@config.indexer).to receive(:render) { "indexer" }
      allow(@config.searchd).to receive(:render) { "searchd" }
      allow(index).to receive(:render) { "source\nindex" }
      expect(File).to receive(:open).with(@config.file.output_path, "w").and_yield(file)
      expect(file).to receive(:write).with("indexer\nsearchd\nsource\nindex")
      @config.render
    end
  end
end
