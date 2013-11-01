require "spec_helper"

describe Mongoid::Giza do
  let(:person_class) do
    class Person
      include Mongoid::Document
      include Mongoid::Giza

      field :name, type: String
      field :age, type: Integer

      search_index do
        field :name
        attribute :age
      end
    end
  end

  let(:index) do
    index = double("index")
    allow(index).to receive(:name) { :Person }
    index
  end

  let(:index_class) { allow(Mongoid::Giza::Index).to receive(:new).with(kind_of(Class)) { index } }

  describe "search_index" do
    context "with a simple field and a simple attribute" do
      it "should create an index" do
        allow(index).to receive(:field).with(:name)
        allow(index).to receive(:attribute).with(:age)
        expect(Mongoid::Giza::Index).to receive(:new) { index }
        person_class
      end

      it "should create an index field" do
        allow(index).to receive(:attribute).with(:age)
        expect(index).to receive(:field).with(:name)
        index_class
        person_class
      end

      it "should create an index attribute" do
        allow(index).to receive(:field).with(:name)
        expect(index).to receive(:attribute).with(:age)
        index_class
        person_class
      end

      it "should register the index" do
        allow(index).to receive(:field).with(:name)
        allow(index).to receive(:attribute).with(:age)
        indexes = double("indexes")
        expect(indexes).to receive(:[]=).with(:Person, index)
        expect(Mongoid::Giza::Instance).to receive(:indexes) { indexes }
        index_class
        person_class
      end
    end
  end
end
