require "spec_helper"

describe Mongoid::Giza::Configuration do
  before do
    source = double("source")
    @default_index = double("default_index")
    allow(Riddle::Configuration::Source).to receive(:new).with(:source, :xmlpipe2) { source }
    allow(Riddle::Configuration::Index).to receive(:new).with(:index, source) { @default_index }
    @config = Mongoid::Giza::Configuration.send(:new)
  end

  describe "initialize" do
    it "should create a Riddle::Configuration::Index for default settings" do
      expect(@config.instance_variable_get("@index")).to be(@default_index)
    end
  end

  describe "load" do
    let(:file) { double("file") }

    let(:file_open) { allow(File).to receive(:open).with("giza.yml") { file } }

    it "should load the configuration file" do
      expect(file).to receive(:read) { "searchd:\n  address: localhost" }
      expect(File).to receive(:open).with("giza.yml") { file }
      @config.load("giza.yml")
    end

    it "should set settings" do
      allow(file).to receive(:read) { "searchd:\n  address: localhost" }
      file_open
      @config.load("giza.yml")
      expect(@config.searchd.address).to eql("localhost")
    end

    it "should ignore non-existent sections" do
      allow(file).to receive(:read) { "miss_section:\n  address: localhost" }
      file_open
      expect { @config.load("giza.yml") }.not_to raise_error
    end

    it "should ignore non-existent settings" do
      allow(file).to receive(:read) { "searchd:\n  miss_setting: false" }
      expect(@config.searchd).not_to receive(:method_missing).with(:miss_setting=, false)
      file_open
      @config.load("giza.yml")
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

    it "should load the default settings" do
      allow(Riddle::Configuration::Index).to receive(:settings) { [:html_strip] }
      allow(@default_index).to receive(:html_strip) { 1 }
      expect(riddle_index).to receive(:html_strip=).with(1)
      @config.add_index(index)
    end

    it "should apply the settings defined" do
      allow(index).to receive(:settings) { {html_strip: 1} }
      expect(riddle_index).to receive(:html_strip=).with(1)
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
  end
end
