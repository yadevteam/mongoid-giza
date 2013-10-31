require "spec_helper"

describe Mongoid::Giza::Config do
  describe "load" do
    let(:file) { double("file") }

    let(:file_open) { allow(File).to receive(:open).with("giza.yml") { file } }

    it "should load the configuration file" do
      expect(file).to receive(:read) { "host: localhost" }
      expect(File).to receive(:open).with("giza.yml") { file }
      Mongoid::Giza::Config.load("giza.yml")
    end

    it "should set the settings" do
      allow(file).to receive(:read) { "host: localhost" }
      file_open
      Mongoid::Giza::Config.load("giza.yml")
      expect(Mongoid::Giza::Config.host).to eql("localhost")
    end

    it "should ignore non-existent settings" do
      allow(file).to receive(:read) { "idontexist: true" }
      expect(Mongoid::Giza::Config).not_to receive(:method_missing).with(:idontexist=, true)
      file_open
      Mongoid::Giza::Config.load("giza.yml")
    end
  end
end
