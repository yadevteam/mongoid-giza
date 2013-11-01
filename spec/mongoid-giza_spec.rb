require "spec_helper"

describe Mongoid::Giza do
  before :all do
    class Person
      include Mongoid::Document
      include Mongoid::Giza

      field :name, type: String
      field :age, type: Integer
    end
  end

  let(:index) do
    index = double("index")
    allow(index).to receive(:name) { :Person }
    index
  end

  let(:new_index) { allow(Mongoid::Giza::Index).to receive(:new).with(Person) { index } }

  let(:config_indexes) { allow(Mongoid::Giza::Instance).to receive(:indexes) { double("indexes").as_null_object } }

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
    end
  end
end
