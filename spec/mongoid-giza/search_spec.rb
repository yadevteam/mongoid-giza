require "spec_helper"

describe Mongoid::Giza::Search do
  let(:client) do
    client = double("client")
    allow(Riddle::Client).to receive(:new).with("localhost", 9132) { client }
    client
  end

  let(:search) { Mongoid::Giza::Search.new("localhost", 9132) }

  let(:filters) do
    filters = double("filters")
    allow(client).to receive(:filters) { filters }
    filters
  end

  let(:filter) { double("filter") }

  it "should create a new client with the given host and port" do
    expect(Riddle::Client).to receive(:new).with("localhost", 9132)
    search
  end

  describe "fulltext" do
    it "should append a query on the specified indexes" do
      expect(client).to receive(:append_query).with("query", "index1 index2")
      allow(search).to receive(:indexes) { "index1 index2" }
      search.fulltext("query")
    end
  end

  describe "indexes" do
    it "should default to '*'" do
      client
      expect(search.indexes).to eql("*")
    end
  end

  describe "with" do
    it "should add a filter to the search" do
      expect(Riddle::Client::Filter).to receive(:new).with("attr", 1, false) { filter }
      expect(filters).to receive(:<<).with(filter)
      client
      search.with(:attr, 1)
    end
  end

  describe "without" do
    it "should add a filter to the search" do
      expect(Riddle::Client::Filter).to receive(:new).with("attr", 1, true) { filter }
      expect(filters).to receive(:<<).with(filter)
      client
      search.without(:attr, 1)
    end
  end

  describe "order_by" do
    it "should set the search order" do
      expect(client).to receive(:sort_by=).with("attr ASC")
      search.order_by(:attr, :asc)
    end
  end

  describe "run" do
    it "should run the query" do
      expect(client).to receive(:run) { [1, 2] }
      search.run
    end

    it "should return the result array" do
      expect(client).to receive(:run) { [1, 2] }
      expect(search.run).to eql([1, 2])
    end

    it "should return a single result if only one query is present" do
      allow(client).to receive(:run) { [{result: true}] }
      expect(search.run).to be_a_kind_of(Hash)
    end
  end

  describe "riddle methods mapping" do
    it "should respond to method from riddle" do
      allow(client).to receive(:respond_to?).with("offset=") { true }
      expect(search.respond_to?(:offset)).to eql(true)
    end

    it "should call the equivalent method from riddle" do
      allow(client).to receive(:respond_to?).with("offset=") { true }
      expect(client).to receive(:offset=).with(1)
      search.offset(1)
    end

    it "should raise an error when the equivalent riddle's method does not exists" do
      allow(client).to receive(:respond_to?).with("idontexist=") { false }
      expect { search.idontexist }.to raise_error(NoMethodError)
    end
  end
end
