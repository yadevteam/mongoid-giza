require "spec_helper"

describe Mongoid::Giza::XMLPipe2 do
  let(:xmlpipe2) { Mongoid::Giza::XMLPipe2.new(@index, @buffer) }

  before do
    @buffer = ""
    @index = double("index")
  end

  describe "generate_schema" do
    before do
      @field = double("field")
      @attribute = double("attribute")
      allow(@index).to receive(:fields) { [@field] }
      allow(@index).to receive(:attributes) { [@attribute] }
      allow(@field).to receive(:name) { :name }
      allow(@attribute).to receive(:name) { :age }
      allow(@attribute).to receive(:type) { :uint }
    end

    it "should generate the schema of the docset" do
      allow(@field).to receive(:attribute) { false }
      xmlpipe2.generate_schema
      expect(@buffer).to eql('<sphinx:schema><sphinx:field name="name"/><sphinx:attr name="age" type="uint"/></sphinx:schema>')
    end

    it "should generate a field attribute" do
      allow(@field).to receive(:attribute) { true }
      xmlpipe2.generate_schema
      expect(@buffer).to eql('<sphinx:schema><sphinx:field name="name" attr="string"/><sphinx:attr name="age" type="uint"/></sphinx:schema>')
    end
  end

  describe "generate_docset" do
    it "should generate the document entries" do
      person = double("Person")
      collection = double("collection")
      field = double("field")
      attribute = double("attribute")
      allow(@index).to receive(:klass) { person }
      allow(@index).to receive(:fields) { [field] }
      allow(@index).to receive(:attributes) { [attribute] }
      allow(person).to receive(:collection) { collection }
      allow(collection).to receive(:find) { [{"giza_id" => 1, "name" => "Person One", "age" => 25}] }
      allow(field).to receive(:name) { :name }
      allow(attribute).to receive(:name) { :age }
      xmlpipe2.generate_docset
      expect(@buffer).to eql('<sphinx:document id="1"><name>Person One</name><age>25</age></sphinx:document>')
    end
  end

  describe "generate!" do
    it "should generate a xml file of the index" do
      result = '<?xml version="1.0" encoding="utf-8"?>'
      result << '<sphinx:docset><sphinx:schema>'
      result << '<sphinx:field name="name"/><sphinx:attr name="age" type="uint"/>'
      result << '</sphinx:schema>'
      result << '<sphinx:document id="1"><name>Person One</name><age>25</age></sphinx:document>'
      result << '</sphinx:docset>'
      expect(xmlpipe2).to receive(:generate_schema) do
        @buffer << '<sphinx:schema><sphinx:field name="name"/><sphinx:attr name="age" type="uint"/></sphinx:schema>'
      end
      expect(xmlpipe2).to receive(:generate_docset) do
        @buffer << '<sphinx:document id="1"><name>Person One</name><age>25</age></sphinx:document>'
      end
      xmlpipe2.generate!
      expect(@buffer).to eql(result)
    end
  end
end
