require "spec_helper"

describe Mongoid::Giza do
  context "a simple field and a simple attribute" do
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
      index = double("index").as_null_object
      allow(index).to receive(:name) { :Person }
      index
    end

    let(:index_class) { allow(Mongoid::Giza::Index).to receive(:new) { index } }

    it "should create an index" do
      expect(Mongoid::Giza::Index).to receive(:new) { index }
      person_class
    end

    it "should create an index field" do
      expect(index).to receive(:field).with(:name)
      index_class
      person_class
    end

    it "should create an index attribute" do
      expect(index).to receive(:attribute).with(:age)
      index_class
      person_class
    end

    it "should register the index" do
      indexes = double("indexes")
      expect(indexes).to receive(:[]=).with(:Person, index)
      expect(Mongoid::Giza::Instance).to receive(:indexes) { indexes }
      index_class
      person_class
    end
  end
end
