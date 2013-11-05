require "spec_helper"

describe Mongoid::Giza do
  before do
    class Person
      include Mongoid::Document
      include Mongoid::Giza

      field :name, type: String
      field :age, type: Integer

      @sphinx_indexes = []
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

  let(:new_index) { allow(Mongoid::Giza::Index).to receive(:new).with(Person) { index } }

  let(:config_indexes) { allow(Mongoid::Giza::Instance).to receive(:indexes) { double("indexes").as_null_object } }

  let(:search) do
    search = double("search")
    allow(Mongoid::Giza::Search).to receive(:new).with("localhost", 9132) { search }
    search
  end

  let(:search_run) { allow(search).to receive(:run) { double("results").as_null_object } }

  let(:search_indexes) { allow(search).to receive(:indexes=) }

  describe "search_index" do
    context "static index" do
      it "should create an index" do
        config_indexes
        expect(Mongoid::Giza::Index).to receive(:new).with(Person) { index }
        Person.search_index { }
      end

      it "should call index methods" do
        config_indexes
        expect(index).to receive(:field).with(:name)
        new_index
        Person.search_index { field :name }
      end

      it "should register the index" do
        indexes = double("indexes")
        expect(indexes).to receive(:[]=).with(:Person, index)
        expect(Mongoid::Giza::Instance).to receive(:indexes) { indexes }
        new_index
        Person.search_index { }
      end

      it "should register the index name on the class" do
        sphinx_indexes = double("sphinx_indexes")
        expect(sphinx_indexes).to receive(:<<).with(index.name)
        Person.instance_variable_set("@sphinx_indexes", sphinx_indexes)
        Person.search_index { }
      end
    end
  end

  describe "search" do
    before do
      allow(Mongoid::Giza::Config).to receive(:host) { "localhost" }
      allow(Mongoid::Giza::Config).to receive(:port) { 9132 }
    end

    it "should create a search" do
      expect(Mongoid::Giza::Search).to receive(:new).with("localhost", 9132) { double("search").as_null_object }
      Person.search {  }
    end

    it "should set the indexes to search to the ones setup on the current class" do
      search_run
      expect(search).to receive(:indexes=).with("Person Person_2")
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
end
