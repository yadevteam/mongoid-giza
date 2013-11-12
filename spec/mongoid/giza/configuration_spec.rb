require "spec_helper"

describe Mongoid::Giza::Configuration do
  let(:config) { Mongoid::Giza::Configuration.instance }

  describe "initialize" do
    it "should create a Riddle::Configuration::Index for default settings" do
      expect(config.instance_variable_get("@index")).to be_a_kind_of(Riddle::Configuration::Index)
    end
  end

  describe "load" do
    let(:file) { double("file") }

    let(:file_open) { allow(File).to receive(:open).with("giza.yml") { file } }

    it "should load the configuration file" do
      expect(file).to receive(:read) { "searchd:\n  address: localhost" }
      expect(File).to receive(:open).with("giza.yml") { file }
      config.load("giza.yml")
    end

    it "should set settings" do
      allow(file).to receive(:read) { "searchd:\n  address: localhost" }
      file_open
      config.load("giza.yml")
      expect(config.searchd.address).to eql("localhost")
    end

    it "should ignore non-existent sections" do
      allow(file).to receive(:read) { "miss_section:\n  address: localhost" }
      file_open
      expect { config.load("giza.yml") }.not_to raise_error
    end

    it "should ignore non-existent settings" do
      allow(file).to receive(:read) { "searchd:\n  miss_setting: false" }
      expect(config.searchd).not_to receive(:method_missing).with(:miss_setting=, false)
      file_open
      config.load("giza.yml")
    end
  end

  describe "add_index" do
    let(:index) do
      index = double("index")
      allow(index).to receive(:name) { :Person }
      allow(index).to receive(:settings) { Hash.new }
      index
    end

    it "should add an Riddle::Configuration::Index" do
      allow(Riddle::Configuration::XMLSource).to receive(:new) { double("source").as_null_object }
      expect { config.add_index(index) }.to change{config.indices.length}.by(1)
    end

    it "should create a xmlpipe2 source with the same name of the index" do
      expect(Riddle::Configuration::XMLSource).to receive(:new).with(index.name, :xmlpipe2) { double("source").as_null_object }
      config.add_index(index)
    end

    it "should apply the settings defined" do
      allow(index).to receive(:settings) { {html_strip: 1} }
      config.add_index(index)
      expect(config.indices.last.html_strip).to eql(1)
    end
  end
end
