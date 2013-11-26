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
      expect(@config.instance_variable_get("@index")).to be(@default_index)
    end

    it "should create a Riddle::Configuration::XMLSource for default settings" do
      expect(@config.instance_variable_get("@source")).to be(@default_source)
    end

    describe "file section" do
      let(:file) { @config.instance_variable_get("@file") }

      it "should create a file section" do
        expect(file).to be_a_kind_of(OpenStruct)
      end

      it "should have output path setting" do
        expect(file.respond_to?(:output_path=)).to be(true)
      end
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
      allow(@config).to receive(:apply_global_settings)
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

    it "should load the global index settings" do
      expect(@config).to receive(:apply_global_settings).with(Riddle::Configuration::Index, @default_index, riddle_index)
      @config.add_index(index)
    end

    it "should load the global index settings" do
      expect(@config).to receive(:apply_global_settings).with(Riddle::Configuration::XMLSource, @default_source, source)
      @config.add_index(index)
    end

    it "should apply the index settings defined" do
      allow(index).to receive(:settings) { {html_strip: 1} }
      allow(riddle_index).to receive(:respond_to?) { true }
      allow(riddle_index).to receive(:respond_to?).with("html_strip=") { true }
      expect(riddle_index).to receive(:html_strip=).with(1)
      @config.add_index(index)
    end

    it "should apply the source settings defined" do
      allow(index).to receive(:settings) { {xmlpipe_command: "cat /path/to/index"} }
      allow(riddle_index).to receive(:respond_to?) { true }
      allow(riddle_index).to receive(:respond_to?).with("xmlpipe_command=") { false }
      allow(source).to receive(:respond_to?).with("xmlpipe_command=") { true }
      expect(source).to receive(:xmlpipe_command=).with("cat /path/to/index")
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

  describe "apply_global_settings" do
    it "should set the global section settings" do
      section = double("section")
      global = double("global")
      instance = double("instance")
      allow(section).to receive(:settings) { [:xmlpipe_command] }
      allow(global).to receive(:xmlpipe_command) { "cat /path/to/index" }
      expect(instance).to receive(:xmlpipe_command=).with("cat /path/to/index")
      @config.apply_global_settings(section, global, instance)
    end
  end
end
