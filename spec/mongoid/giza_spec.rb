require "spec_helper"

describe Mongoid::Giza do
  let(:index) { double("index") }

  let(:search) { double("search") }

  let(:config) { Mongoid::Giza::Configuration.instance }

  before do
    # :nodoc:
    class Person
      include Mongoid::Document
      include Mongoid::Attributes::Dynamic
      include Mongoid::Giza

      field :name, type: String
      field :age, type: Integer
    end

    allow(Mongoid::Giza::Configuration.instance).to receive(:add_index)
    allow(Mongoid::Giza::Search).to receive(:new)
      .with("localhost", 9132, []) { search }
    allow(search).to receive(:run) { double("results").as_null_object }
    allow(search).to receive(:indexes=)
  end

  after do
    Object.send(:remove_const, :Person)
  end

  describe "sphinx_index" do
    context "static index" do
      it "should add the index" do
        expect(Person).to receive(:add_static_sphinx_index)
          .with({}, kind_of(Proc))
        Person.sphinx_index {}
      end
    end

    context "dynamic index" do
      it "should add the index to the dynamic index list" do
        expect(Person).to receive(:add_dynamic_sphinx_index)
          .with({}, kind_of(Proc))
        Person.sphinx_index { |person| person }
      end
    end
  end

  describe "add_static_sphinx_index" do
    before do
      allow(Mongoid::Giza::Index).to receive(:new).with(Person, {}) { index }
      allow(index).to receive(:name) { :Person }
    end

    it "should create an index" do
      expect(Mongoid::Giza::Index).to receive(:new).with(Person, {}) { index }
      Person.add_static_sphinx_index({}, -> {})
    end

    it "should call index methods" do
      expect(index).to receive(:field).with(:name)
      Person.add_static_sphinx_index({}, -> { field :name })
    end

    it "should register the index on the class" do
      sphinx_indexes = double("sphinx_indexes")
      expect(sphinx_indexes).to receive(:[]=).with(index.name, index)
      allow(Person).to receive(:static_sphinx_indexes) { sphinx_indexes }
      Person.add_static_sphinx_index({}, -> {})
    end

    it "should accept settings" do
      expect(Mongoid::Giza::Index).to receive(:new)
        .with(Person, enable_star: 1) { index }
      Person.add_static_sphinx_index({enable_star: 1}, -> {})
    end

    it "should add the index to the configuration" do
      expect(config).to receive(:add_index).with(index)
      Person.add_static_sphinx_index({}, -> {})
    end
  end

  describe "add_dynamic_sphinx_index" do
    let(:dynamic_index) { double("dynamic index") }

    before do
      allow(Person).to receive(:process_dynamic_sphinx_index)
    end

    it "should create a dynamic index" do
      allow(Person).to receive(:generated_sphinx_indexes) do
        double.as_null_object
      end
      expect(Mongoid::Giza::DynamicIndex).to receive(:new)
        .with(Person, {}, kind_of(Proc)) { double.as_null_object }
      Person.add_dynamic_sphinx_index({}, -> {})
    end

    it "should generate the indexes" do
      allow(Mongoid::Giza::DynamicIndex).to receive(:new) { dynamic_index }
      expect(Person).to receive(:process_dynamic_sphinx_index)
        .with(dynamic_index)
      Person.add_dynamic_sphinx_index({}, -> {})
    end
  end

  describe "process_dynamic_sphinx_index" do
    let(:dynamic_index) { double("dynamic index") }

    let(:generated) { double("generated") }

    let(:generated_sphinx_indexes) { double("sphinx generated indexes") }

    before do
      allow(generated).to receive(:each)
      allow(Person).to receive(:generated_sphinx_indexes) do
        generated_sphinx_indexes
      end
      allow(generated_sphinx_indexes).to receive(:merge!)
    end

    it "should generate the indexes" do
      expect(dynamic_index).to receive(:generate!) { {} }
      Person.process_dynamic_sphinx_index(dynamic_index)
    end

    it "should merge the generated indexes" do
      allow(dynamic_index).to receive(:generate!) { generated }
      expect(generated_sphinx_indexes).to receive(:merge!).with(generated)
      Person.process_dynamic_sphinx_index(dynamic_index)
    end

    it "should add the generated indexes to the configuration" do
      allow(dynamic_index).to receive(:generate!) { generated }
      allow(generated).to receive(:each).and_yield(:name, :generated_index)
      expect(config).to receive(:add_index).with(:generated_index, true)
      Person.process_dynamic_sphinx_index(dynamic_index)
    end
  end

  describe "search" do
    let(:mapped_results) { double("mapped results") }

    before do
      allow(Mongoid::Giza::Configuration.instance.searchd)
        .to receive(:address) { "localhost" }
      allow(Mongoid::Giza::Configuration.instance.searchd)
        .to receive(:port) { 9132 }
    end

    it "should create a search" do
      expect(Mongoid::Giza::Search).to receive(:new)
        .with("localhost", 9132, [:Person, :Person_2]) do
          double("search").as_null_object
        end
      Person.sphinx_index {}
      Person.sphinx_index { name :Person_2 }
      Person.search {}
    end

    it "should call search methods" do
      expect(search).to receive(:fulltext).with("query")
      Person.search { fulltext "query" }
    end

    it "should run the query" do
      expect(search).to receive(:run)
      Person.search {}
    end

    it "should retur map_to_mongoid" do
      expect(Person).to receive(:map_to_mongoid) { mapped_results }
      Person.search {}
    end
  end

  describe "sphinx_indexes" do
    it "should return an collection containg static indexes and generated " \
      "indexes" do
      static = double("static")
      generated = double("generated")
      merged = double("merged")
      allow(Person).to receive(:static_sphinx_indexes) { static }
      allow(Person).to receive(:generated_sphinx_indexes) { generated }
      allow(static).to receive(:merge).with(generated) { merged }
      expect(Person.sphinx_indexes).to be(merged)
    end
  end

  describe "sphinx_indexer!" do
    let(:indexer) { Mongoid::Giza::Indexer.instance }

    it "should execute the index with all indexes from this class" do
      expect(indexer).to receive(:index!).with(:Person, :Person_2)
      Person.sphinx_index {}
      Person.sphinx_index { name :Person_2 }
      Person.sphinx_indexer!
    end

    it "should accept a list of indexes names" do
      expect(indexer).to receive(:index!).with(:Person, :Person_3)
      Person.sphinx_index {}
      Person.sphinx_index { name :Person_2 }
      Person.sphinx_index { name :Person_3 }
      Person.sphinx_indexer!(:Person, :Person_3)
    end

    it "should not execute if the class has no indexes" do
      expect(indexer).not_to receive(:index!)
      Person.sphinx_indexer!
    end

    it "should not execute if the supplied names do not match any index name " \
      "of the current class" do
      expect(indexer).not_to receive(:index!)
      Person.sphinx_index {}
      Person.sphinx_indexer!(:Person_2)
    end
  end

  describe "sphinx_indexes_names" do
    it "should return the name of all indexes" do
      static = double("static")
      generated = double("generated")
      merged = double("merged")
      names = double("names")
      allow(Person).to receive(:static_sphinx_indexes) { static }
      allow(Person).to receive(:generated_sphinx_indexes) { generated }
      allow(static).to receive(:merge).with(generated) { merged }
      allow(merged).to receive(:keys) { names }
      expect(Person.sphinx_indexes_names).to be(names)
    end
  end

  describe "regenerate_sphinx_indexes" do
    let(:generated) { double("generated") }

    let(:dynamic) { double("dynamic") }

    let(:keys) { double("keys") }

    before do
      allow(Person).to receive(:generated_sphinx_indexes) { generated }
      allow(generated).to receive(:keys) { keys }
      allow(generated).to receive(:clear)
      allow(config).to receive(:remove_generated_indexes)
    end

    it "should clear the generated indexes configuration" do
      expect(config).to receive(:remove_generated_indexes).with(keys)
      Person.regenerate_sphinx_indexes
    end

    it "should clear the generated indexes" do
      expect(generated).to receive(:clear).with(no_args)
      Person.regenerate_sphinx_indexes
    end

    it "should process all dynamic indexes" do
      allow(Person).to receive(:dynamic_sphinx_indexes) { dynamic }
      allow(dynamic).to receive(:each).and_yield(:dynamic_index)
      expect(Person).to receive(:process_dynamic_sphinx_index)
        .with(:dynamic_index)
      Person.regenerate_sphinx_indexes
    end
  end

  describe "generate_sphinx_indexes" do
    let(:person) { Person.new }

    let(:dynamic_index) { double("dynamic index") }

    let(:dynamic_index2) { double("dynamic index 2") }

    let(:index) { double("index") }

    let(:index2) { double("index 2") }

    before do
      allow(Person)
        .to receive(:dynamic_sphinx_indexes) { [dynamic_index, dynamic_index] }
      allow(dynamic_index).to receive(:generate_index) { index }
      allow(index).to receive(:name) { :name }
    end

    it "should generate all the dynamic indexes of the class for the object" do
      expect(dynamic_index).to receive(:generate_index).with(person)
        .twice { index }
      person.generate_sphinx_indexes
    end

    it "should merge the resulting indexes to the class' generated indexes" do
      person.generate_sphinx_indexes
      expect(Person.generated_sphinx_indexes[:name]).to be(index)
    end

    it "should add the indexes to the configuration" do
      expect(config).to receive(:add_index).with(index, true).twice
      person.generate_sphinx_indexes
    end
  end

  describe "remove_generated_sphinx_indexes" do
    let(:index_name) { double("index name") }

    it "should remove the indexes from the generated indexes collection" do
      expect(Person.generated_sphinx_indexes).to receive(:delete)
        .with(index_name).twice
      Person.remove_generated_sphinx_indexes(index_name, index_name)
    end

    it "should remove the indexes from the configuration" do
      expect(config).to receive(:remove_generated_indexes)
        .with([index_name, index_name])
      Person.remove_generated_sphinx_indexes(index_name, index_name)
    end
  end

  describe "map_to_mongoid" do
    it "should return an result hash" do
      allow(Person).to receive(:in) { Mongoid::Criteria.new(Person) }
      expect(Person.send(:map_to_mongoid, matches: [])).to be_a_kind_of(Hash)
    end

    it "should add an entry with the Mongoid::Criteria Hash" do
      allow(Person).to receive(:in) { Mongoid::Criteria.new(Person) }
      result = Person.send(:map_to_mongoid, matches: [])
      expect(result).to include(:Person)
    end
  end
end
