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

  let(:config_indexes) { allow(Mongoid::Giza::Instance).to receive(:indexes) { double("indexes").as_null_object } }

  let(:search) do
    search = double("search")
    allow(Mongoid::Giza::Search).to receive(:new).with("localhost", 9132, nil) { search }
    search
  end

  let(:search_run) { allow(search).to receive(:run) { double("results").as_null_object } }

  let(:search_indexes) { allow(search).to receive(:indexes=) }

  let(:config) { Mongoid::Giza::Configuration.instance }

  describe "search_index" do
    context "static index" do
      it "should create an index" do
        config_indexes
        expect(Mongoid::Giza::Index).to receive(:new).with(Person, {}) { index }
        Person.search_index { }
      end

      it "should call index methods" do
        config_indexes
        expect(index).to receive(:field).with(:name)
        new_index
        Person.search_index { field :name }
      end

      it "should register the index on the class" do
        sphinx_indexes = double("sphinx_indexes")
        expect(sphinx_indexes).to receive(:[]=).with(index.name, index)
        allow(Person).to receive(:sphinx_indexes) { sphinx_indexes }
        new_index
        Person.search_index { }
      end

      it "should accept settings" do
        config_indexes
        expect(Mongoid::Giza::Index).to receive(:new).with(Person, enable_star: 1) { index }
        Person.search_index(enable_star: 1) { }
      end

      it "should add the index to the configuration" do
        expect(config).to receive(:add_index).with(index)
        new_index
        Person.search_index { }
      end
    end
  end

  describe "search" do
    before do
      allow(Mongoid::Giza::Configuration.instance.searchd).to receive(:address) { "localhost" }
      allow(Mongoid::Giza::Configuration.instance.searchd).to receive(:port) { 9132 }
    end

    it "should create a search" do
      expect(Mongoid::Giza::Search).to receive(:new).with("localhost", 9132, "Person Person_2") { double("search").as_null_object }
      Person.search_index { }
      Person.search_index { name :Person_2 }
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

    it "should return only one result when only one query was defined" do
      search_indexes
      allow(search).to receive(:run) { [{matches: []}] }
      allow(Person).to receive(:in) { Mongoid::Criteria.new(Person) }
      expect(Person.search { }).to be_a_kind_of(Hash)
    end

    it "should return an array of results when multiple queries were defined" do
      search_indexes
      allow(search).to receive(:run) { [{matches: []}, {matches: []}] }
      allow(Person).to receive(:in) { Mongoid::Criteria.new(Person) }
      expect(Person.search { }).to be_a_kind_of(Array)
    end

    it "should return a Mongoid::Criteria with the search results" do
      search_indexes
      allow(search).to receive(:run) { [{matches: []}] }
      allow(Person).to receive(:in) { Mongoid::Criteria.new(Person) }
      results =  Person.search { }
      expect(results[:Person]).to be_a_kind_of(Mongoid::Criteria)
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
    it "should return an empty collection when no indexes are defined" do
      expect(Person.sphinx_indexes).to eql({})
    end

    it "should return the defined indexes for the class" do
      Person.instance_variable_set("@sphinx_indexes", {a: 1})
      expect(Person.sphinx_indexes).to eql({a: 1})
    end
  end

  describe "sphinx_indexer!" do
    let(:indexer) { Mongoid::Giza::Indexer.instance }

    it "should execute the index with all indexes from this class" do
      expect(indexer).to receive(:index!).with(kind_of(Mongoid::Giza::Index), kind_of(Mongoid::Giza::Index))
      Person.search_index { }
      Person.search_index { name :Person_2 }
      Person.sphinx_indexer!
    end

    it "should accept a list of indexes names" do
      expect(indexer).to receive(:index!).with(kind_of(Mongoid::Giza::Index), kind_of(Mongoid::Giza::Index))
      Person.search_index { }
      Person.search_index { name :Person_2 }
      Person.search_index { name :Person_3 }
      Person.sphinx_indexer!(:Person, :Person_3)
    end

    it "should not execute if the class has no indexes" do
      expect(indexer).not_to receive(:index!)
      Person.sphinx_indexer!
    end
  end
end
