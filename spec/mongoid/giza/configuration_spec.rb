require "spec_helper"

describe Mongoid::Giza::Configuration do
  describe "load" do
    let(:file) { double("file") }

    let(:file_open) { allow(File).to receive(:open).with("giza.yml") { file } }

    let(:config) { Mongoid::Giza::Configuration.instance }

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
end
