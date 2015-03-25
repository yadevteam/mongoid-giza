require "spec_helper"

describe Mongoid::Giza::Configuration do
  before do
    @default_source = double("default_source")
    @default_index = double("default_index")
    allow(Riddle::Configuration::XMLSource).to receive(:new)
      .with(:source, :xmlpipe2) { @default_source }
    allow(Riddle::Configuration::Index).to receive(:new)
      .with(:index, @default_source) { @default_index }
    @config = Mongoid::Giza::Configuration.send(:new)
  end

  describe "initialize" do
    it "should create a Riddle::Configuration::Index for default settings" do
      expect(@config.index).to be(@default_index)
    end

    it "should create a Riddle::Configuration::XMLSource for default " \
      "settings" do
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
      expect(file).to receive(:read) do
        "test:\n  searchd:\n    address: localhost"
      end
      expect(File).to receive(:open).with("giza.yml") { file }
      @config.load("giza.yml", "test")
    end

    it "should set settings" do
      allow(file).to receive(:read) do
        "test:\n  searchd:\n    address: localhost"
      end
      file_open
      @config.load("giza.yml", "test")
      expect(@config.searchd.address).to eql("localhost")
    end

    it "should ignore non-existent sections" do
      allow(file).to receive(:read) do
        "test:\n  miss_section:\n    address: localhost"
      end
      file_open
      expect { @config.load("giza.yml", "test") }.not_to raise_error
    end

    it "should ignore non-existent settings" do
      allow(file).to receive(:read) do
        "test:\n  searchd:\n    miss_setting: false"
      end
      expect(@config.searchd).not_to receive(:method_missing)
        .with(:miss_setting=, false)
      file_open
      @config.load("giza.yml", "test")
    end

    it "should interpolate the string with ERB" do
      allow(file).to receive(:read) do
        "test:\n  searchd:\n    address: localhost"
      end
      expect(@config).to receive(:interpolate_string).with("localhost", nil)
      file_open
      @config.load("giza.yml", "test")
    end

    it "should not interpolate index settings" do
      allow(file).to receive(:read) { "test:\n  index:\n    path: home" }
      expect(@config).not_to receive(:interpolate_string)
      file_open
      @config.load("giza.yml", "test")
    end

    it "should not interpolate source settings" do
      allow(file).to receive(:read) do
        "test:\n  source:\n    xmlpipe_command: cmd"
      end
      expect(@config).not_to receive(:interpolate_string)
      file_open
      @config.load("giza.yml", "test")
    end
  end

  describe "add_index" do
    let(:indices) { double("indices") }

    let(:index) { double("index") }

    let(:riddle_index) { double("riddle index") }

    let(:length) { double("length") }

    let(:static) { double("static") }

    let(:generated) { double("generated") }

    before do
      allow(@config).to receive(:indices) { indices }
      allow(@config).to receive(:create_index) { riddle_index }
      allow(@config).to receive(:register_index) { length }
      allow(indices).to receive(:<<)
      allow(indices).to receive(:[]=)
      allow(index).to receive(:name)
    end

    it "should create a new riddle index" do
      expect(@config).to receive(:create_index).with(index)
      @config.add_index(index)
    end

    it "should add the index to the configuration indices" do
      expect(indices).to receive(:[]=).with(length, riddle_index)
      @config.add_index(index)
    end

    it "should register a static index on the static indexes hash" do
      @config.instance_variable_set("@static_indexes", static)
      expect(@config).to receive(:register_index).with(riddle_index, static)
      @config.add_index(index)
    end

    it "should register a generated index on the generated indexes hash" do
      @config.instance_variable_set("@generated_indexes", generated)
      expect(@config).to receive(:register_index).with(riddle_index, generated)
      @config.add_index(index, true)
    end
  end

  describe "create_index" do
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
      allow(Riddle::Configuration::Index).to receive(:new)
        .with(index.name, source) { riddle_index }
      allow(@config).to receive(:apply_default_settings)
      allow(@config).to receive(:apply_user_settings)
    end

    it "should create a xmlpipe2 source with the same name of the index" do
      expect(Riddle::Configuration::XMLSource).to receive(:new)
        .with(index.name, :xmlpipe2) { source }
      allow(Riddle::Configuration::Index).to receive(:new) do
        double("riddle_index").as_null_object
      end
      @config.create_index(index)
    end

    it "should set the path" do
      allow(Riddle::Configuration::Index).to receive(:settings) { [:path] }
      allow(@default_index).to receive(:path) { "/path/to/index" }
      allow(riddle_index).to receive(:path=).with("/path/to/index")
      allow(riddle_index).to receive(:path) { "/path/to/index" }
      expect(riddle_index).to receive(:path=)
        .with("/path/to/index/#{index.name}")
      @config.create_index(index)
    end

    it "should apply default settings to the index" do
      expect(@config).to receive(:apply_default_settings)
        .with(@default_index, riddle_index, index)
      @config.create_index(index)
    end

    it "should apply default settings to the source" do
      expect(@config).to receive(:apply_default_settings)
        .with(@default_source, source, index)
      @config.create_index(index)
    end

    it "should apply user defined settings to the index" do
      expect(@config).to receive(:apply_user_settings).with(index, riddle_index)
      @config.create_index(index)
    end

    it "should apply user defined settings to the source" do
      expect(@config).to receive(:apply_user_settings).with(index, source)
      @config.create_index(index)
    end

    it "should return the index" do
      expect(@config.create_index(index)).to be(riddle_index)
    end
  end

  describe "register_index" do
    let(:riddle_index) do
      instance_double("Riddle::Configuration::Index", name: "name")
    end

    let(:riddle_index_copy) do
      instance_double("Riddle::Configuration::Index", name: "name")
    end

    let(:indexes) { {riddle_index.name => riddle_index} }

    it "should add the index to the given hash" do
      @config.register_index(riddle_index, indexes)
      expect(indexes).to include riddle_index.name => riddle_index
    end

    it "should return the position of the index in the indices array" do
      @config.indices.push(riddle_index)
      position = @config.register_index(riddle_index_copy, indexes)
      expect(position).to eql 0
    end

    it "should return the indices array length if it's not on the array" do
      position = @config.register_index(riddle_index, indexes)
      expect(position).to eql @config.indices.length
    end
  end

  describe "apply_default_settings" do
    before do
      @default = double("default")
      @section = double("section")
      @index = double("index")
      allow(@default).to receive(:class) do
        klass = double("class")
        allow(klass).to receive(:settings) { [:html_strip] }
        klass
      end
    end

    it "should apply the settings from default to section" do
      allow(@default).to receive(:html_strip) { 1 }
      expect(@config).to receive(:setter).with(@section, :html_strip, 1)
      @config.apply_default_settings(@default, @section, @index)
    end

    it "should not set nil values" do
      allow(@default).to receive(:html_strip) { nil }
      expect(@config).not_to receive(:setter)
      @config.apply_default_settings(@default, @section, @index)
    end

    it "should interpolate string values" do
      allow(@default).to receive(:html_strip) { 1 }
      expect(@config).to receive(:interpolate_string).with(1, @index)
      @config.apply_default_settings(@default, @section, @index)
    end
  end

  describe "apply_user_settings" do
    before do
      @index = double("index")
      @section = double("section")
      allow(@index).to receive(:settings) { {html_strip: 1} }
      allow(@section).to receive(:html_strip=)
    end

    it "should apply the the settings" do
      expect(@config).to receive(:setter).with(@section, :html_strip, 1)
      @config.apply_user_settings(@index, @section)
    end

    it "should interpolate the value" do
      expect(@config).to receive(:interpolate_string).with(1, @index)
      @config.apply_user_settings(@index, @section)
    end
  end

  describe "interpolate_string" do
    let(:string) { double("string") }

    let(:index) { double("index") }

    let(:namespace) { double("namespace") }

    let(:erb) { double("erb") }

    let(:binding) { double("binding") }

    let(:result) { double("result") }

    before do
      allow(string).to receive(:is_a?) { false }
      allow(string).to receive(:is_a?).with(String) { true }
      allow(ERB).to receive(:new).with(string) { erb }
      allow(erb).to receive(:result) { result }
    end

    it "should ignore non string values" do
      expect(@config.interpolate_string(1, index)).to eql(1)
    end

    it "should create the namespace" do
      expect(OpenStruct).to receive(:new).with(index: index)
      @config.interpolate_string(string, index)
    end

    it "should return the interpolation result" do
      allow(namespace).to receive(:binding) { binding }
      allow(erb).to receive(:result).with(binding) { result }
      expect(@config.interpolate_string(string, index)).to be(result)
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
      expect(File).to receive(:open).with(@config.file.output_path, "w")
        .and_yield(file)
      expect(file).to receive(:write).with("\nindexer\nsearchd\nsource\nindex")
      @config.render
    end
  end

  describe "clear_generated_indexes" do
    let(:indices) { double("indices") }

    before do
      @config.instance_variable_set("@generated_indexes", name: :index)
    end

    it "should delete the generated riddle indexes" do
      allow(@config).to receive(:indices) { indices }
      expect(indices).to receive(:delete).with(:index)
      @config.clear_generated_indexes
    end

    it "should clear the generated indexes collection" do
      @config.clear_generated_indexes
      expect(@config.instance_variable_get("@generated_indexes")).to eql({})
    end
  end

  describe "setter" do
    let(:section) { double("section")  }

    let(:value) { double("value") }

    before do
      allow(section).to receive(:respond_to?) { true }
    end

    it "should use the attribute setter on the section" do
      expect(section).to receive("setting=").with(value)
      @config.setter(section, :setting, value)
    end

    it "should no set the value if the section does not respond to the " \
      "attribute setter" do
      allow(section).to receive(:respond_to?).with("setting=") { false }
      expect(section).not_to receive("setting=")
      @config.setter(section, :setting, value)
    end
  end

  describe "remove_generated_indexes" do
    let(:indices) { double("indices")  }

    before do
      @config.instance_variable_set("@generated_indexes", name: :index,
                                                          two: :index2)
    end

    it "should remove the indexes from the indices array" do
      allow(@config).to receive(:indices) { indices }
      expect(indices).to receive(:delete).with(:index)
      @config.remove_generated_indexes([:name])
    end

    it "should remove the index from the generated indexes collection" do
      @config.remove_generated_indexes([:name])
      expect(@config.instance_variable_get("@generated_indexes"))
        .not_to include(name: :index)
    end
  end
end
