require "spec_helper"

describe Mongoid::Giza do
  before do
    allow(Mongoid::Giza::GizaID).to receive(:create).with(id: :Person)
    allow(Mongoid::Giza::Configuration.instance).to receive(:add_index)

    class Person
      include Mongoid::Document
      include Mongoid::Giza

      field :name, type: String
      field :age, type: Integer
    end
  end

  after do
    Object.send(:remove_const, :Person)
  end

  let(:index) do
    index = double("index")
    allow(index).to receive(:name) { :Person }
    index
  end

  let(:new_index) { allow(Mongoid::Giza::Index).to receive(:new).with(Person, {}) { index } }

  let(:search) do
    search = double("search")
    allow(Mongoid::Giza::Search).to receive(:new).with("localhost", 9132) { search }
    search
  end

  let(:search_run) { allow(search).to receive(:run) { double("results").as_null_object } }

  let(:search_indexes) { allow(search).to receive(:indexes=) }

  let(:config) { Mongoid::Giza::Configuration.instance }

  describe "sphinx_index" do
    context "static index" do
      it "should add the index" do
        expect(Person).to receive(:add_static_sphinx_index).with({}, kind_of(Proc))
        Person.sphinx_index { }
      end
    end

    context "dynamic index" do
      it "should add the index to the dynamic index list" do
        expect(Person).to receive(:add_dynamic_sphinx_index).with({}, kind_of(Proc))
        Person.sphinx_index { |person| }
      end
    end
  end

  describe "add_static_sphinx_index" do
    it "should create an index" do
      expect(Mongoid::Giza::Index).to receive(:new).with(Person, {}) { index }
      Person.add_static_sphinx_index({}, Proc.new { })
    end

    it "should call index methods" do
      expect(index).to receive(:field).with(:name)
      new_index
      Person.add_static_sphinx_index({}, Proc.new { field :name })
    end

    it "should register the index on the class" do
      sphinx_indexes = double("sphinx_indexes")
      expect(sphinx_indexes).to receive(:[]=).with(index.name, index)
      allow(Person).to receive(:static_sphinx_indexes) { sphinx_indexes }
      new_index
      Person.add_static_sphinx_index({}, Proc.new { })
    end

    it "should accept settings" do
      expect(Mongoid::Giza::Index).to receive(:new).with(Person, enable_star: 1) { index }
      Person.add_static_sphinx_index({enable_star: 1}, Proc.new { })
    end

    it "should add the index to the configuration" do
      expect(config).to receive(:add_index).with(index)
      new_index
      Person.add_static_sphinx_index({}, Proc.new { })
    end
  end

  describe "add_dynamic_sphinx_index" do
    let(:dynamic_index) { double("dynamic index") }

    before do
      allow(Person).to receive(:process_dynamic_sphinx_index)
    end

    it "should create a dynamic index" do
      allow(Person).to receive(:generated_sphinx_indexes) { double.as_null_object }
      expect(Mongoid::Giza::DynamicIndex).to receive(:new).with(Person, {}, kind_of(Proc)) { double.as_null_object }
      Person.add_dynamic_sphinx_index({}, Proc.new { })
    end

    it "should generate the indexes" do
      allow(Mongoid::Giza::DynamicIndex).to receive(:new) { dynamic_index }
      expect(Person).to receive(:process_dynamic_sphinx_index).with(dynamic_index)
      Person.add_dynamic_sphinx_index({}, Proc.new { })
    end
  end

  describe "process_dynamic_sphinx_index" do
    let(:dynamic_index) { double("dynamic index") }

    let(:generated) { double("generated") }

    let(:generated_sphinx_indexes) { double("sphinx generated indexes") }

    before do
      allow(generated).to receive(:each)
      allow(Person).to receive(:generated_sphinx_indexes) { generated_sphinx_indexes }
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
    before do
      allow(Mongoid::Giza::Configuration.instance.searchd).to receive(:address) { "localhost" }
      allow(Mongoid::Giza::Configuration.instance.searchd).to receive(:port) { 9132 }
    end

    it "should create a search" do
      expect(Mongoid::Giza::Search).to receive(:new).with("localhost", 9132, :Person, :Person_2) { double("search").as_null_object }
      Person.sphinx_index { }
      Person.sphinx_index { name :Person_2 }
      Person.search {  }
    end

    it "should call search methods" do
      search_run
      search_indexes
      expect(search).to receive(:fulltext).with("query")
      Person.search { fulltext "query" }
    end

    it "should run the query" do
      search_run
      search_indexes
      Person.search { }
    end

    it "should return an array of results" do
      search_indexes
      allow(search).to receive(:run) { [{matches: []}, {matches: []}] }
      allow(Person).to receive(:in) { Mongoid::Criteria.new(Person) }
      expect(Person.search { }).to be_a_kind_of(Array)
    end

    it "should return a Mongoid::Criteria with on each search results" do
      search_indexes
      allow(search).to receive(:run) { [{matches: []}, {matches: []}] }
      expect(Person).to receive(:in).twice { Mongoid::Criteria.new(Person) }
      Person.search { }
    end
  end

  describe "giza_id" do
    let(:person) { Person.new }

    it "should use a previously created giza id" do
      person[:giza_id] = 1
      expect(person.giza_id).to eql(1)
    end

    it "should create a new giza id when needed" do
      allow(Mongoid::Giza::GizaID).to receive(:next_id).with(:Person) { 1 }
      expect(person.giza_id).to eql(1)
    end

    it "should save the object when the id is created" do
      allow(Mongoid::Giza::GizaID).to receive(:next_id).with(:Person) { 1 }
      expect(person).to receive(:set).with(:giza_id, 1)
      person.giza_id
    end

    it "should not save the object when the id is reused" do
      person[:giza_id] = 1
      expect(person).not_to receive(:set)
      person.giza_id
    end
  end

  describe "sphinx_indexes" do
    it "should return an collection containg static indexes and generated indexes" do
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
      Person.sphinx_index { }
      Person.sphinx_index { name :Person_2 }
      Person.sphinx_indexer!
    end

    it "should accept a list of indexes names" do
      expect(indexer).to receive(:index!).with(:Person, :Person_3)
      Person.sphinx_index { }
      Person.sphinx_index { name :Person_2 }
      Person.sphinx_index { name :Person_3 }
      Person.sphinx_indexer!(:Person, :Person_3)
    end

    it "should not execute if the class has no indexes" do
      expect(indexer).not_to receive(:index!)
      Person.sphinx_indexer!
    end

    it "should not execute if the supplied names do not match any index name of the current class" do
      expect(indexer).not_to receive(:index!)
      Person.sphinx_index { }
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

  describe "regenerate_dynamic_sphinx_indexes" do
    let(:generated) { double("generated") }

    let(:dynamic) { double("dynamic") }

    it "should clear the generated indexes" do
      allow(Person).to receive(:generated_sphinx_indexes) { generated }
      expect(generated).to receive(:clear)
      Person.regenerate_dynamic_sphinx_indexes
    end

    it "should process all dynamic indexes" do
      allow(Person).to receive(:dynamic_sphinx_indexes) { dynamic }
      allow(dynamic).to receive(:each).and_yield(:dynamic_index)
      expect(Person).to receive(:process_dynamic_sphinx_index).with(:dynamic_index)
      Person.regenerate_dynamic_sphinx_indexes
    end
  end

  describe "clear_generated_sphinx_indexes_configuration" do
    it "should remove all generated indexes of this class from the configuration" do
      allow(Person).to receive(:generated_sphinx_indexes) { {index1: :index, index2: :index} }
      expect(config).to receive(:remove_generated_indexes).with([:index1, :index2])
      Person.clear_generated_sphinx_indexes_configuration
    end
  end

  describe "generate_dynamic_sphinx_indexes" do
    let(:person) { Person.new }

    let(:dynamic_index) { double("dynamic index") }

    let(:dynamic_index2) { double("dynamic index 2") }

    let(:index) { double("index") }

    let(:index2) { double("index 2") }

    before do
      allow(Person).to receive(:dynamic_sphinx_indexes) { [dynamic_index, dynamic_index] }
      allow(dynamic_index).to receive(:generate_index) { index }
      allow(index).to receive(:name) { :name }
    end

    it "should generate all the dynamic indexes of the class for the object" do
      expect(dynamic_index).to receive(:generate_index).with(person).twice { index }
      person.generate_dynamic_sphinx_indexes
    end

    it "should merge the resulting indexes to the class' generated indexes" do
      expect(Person.generated_sphinx_indexes).to receive(:merge!).with({name: index}).twice
      person.generate_dynamic_sphinx_indexes
    end

    it "should add the indexes to the configuration" do
      expect(config).to receive(:add_index).with(index, true).twice
      person.generate_dynamic_sphinx_indexes
    end
  end
end
