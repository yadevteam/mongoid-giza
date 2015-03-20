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
      allow(@field).to receive(:attribute)
      allow(@attribute).to receive(:name) { :age }
      allow(@attribute).to receive(:type) { :int }
      allow(@attribute).to receive(:default)
      allow(@attribute).to receive(:bits)
    end

    it "should generate the schema of the docset" do
      xmlpipe2.generate_schema
      expect(@buffer).to eql('<sphinx:schema><sphinx:field name="name"/>' \
        '<sphinx:attr name="age" type="int"/></sphinx:schema>')
    end

    it "should generate a field attribute" do
      allow(@field).to receive(:attribute) { true }
      xmlpipe2.generate_schema
      expect(@buffer).to eql('<sphinx:schema><sphinx:field name="name" '\
        'attr="string"/><sphinx:attr name="age" type="int"/></sphinx:schema>')
    end

    it "should include default attribute if present" do
      allow(@attribute).to receive(:default) { 1 }
      xmlpipe2.generate_schema
      expect(@buffer).to eql('<sphinx:schema><sphinx:field name="name"/>' \
        '<sphinx:attr name="age" type="int" default="1"/></sphinx:schema>')
    end

    it "should include bits attribute if present" do
      allow(@attribute).to receive(:bits) { 16 }
      xmlpipe2.generate_schema
      expect(@buffer).to eql('<sphinx:schema><sphinx:field name="name"/>' \
        '<sphinx:attr name="age" type="int" bits="16"/></sphinx:schema>')
    end
  end

  describe "generate_docset" do
    before do
      field = double("field")
      attribute = double("attribute")
      person = double("person")
      allow(@index).to receive(:fields) { [field] }
      allow(@index).to receive(:attributes) { [attribute] }
      allow(@index).to receive(:criteria) { [person] }
      allow(person).to receive(:_giza_id) { 1 }
      allow(xmlpipe2).to receive(:generate_doc_tags).with([field], person) do
        @buffer << "<name>Person One</name>"
      end
      allow(xmlpipe2).to receive(:generate_doc_tags)
        .with([attribute], person) { @buffer << "<age>25</age>" }
    end

    context "static fields and attributes" do
      it "should generate the document entries" do
        xmlpipe2.generate_docset
        expect(@buffer).to eql('<sphinx:document id="1"><name>Person One' \
          "</name><age>25</age></sphinx:document>")
      end
    end
  end

  describe "generate_doc_tags" do
    before do
      name = double("name")
      bio = double("bio")
      @fields = [name, bio]
      @person = {name: "Person One", bio: "About me"}
      allow(name).to receive(:name) { :name }
      allow(name).to receive(:block) do
        proc { |document| document[:name].upcase }
      end
      allow(bio).to receive(:name) { :bio }
      allow(bio).to receive(:block) { nil }
    end

    it "should generate all tags for the given fields or attributes" do
      xmlpipe2.generate_doc_tags(@fields, @person)
      expect(@buffer).to eql("<name>PERSON ONE</name><bio>About me</bio>")
    end
  end

  describe "generate!" do
    it "should generate a xml file of the index" do
      result = '<?xml version="1.0" encoding="utf-8"?>'
      result << "<sphinx:docset><sphinx:schema>"
      result <<
        '<sphinx:field name="name"/><sphinx:attr name="age" type="int"/>'
      result << "</sphinx:schema>"
      result << '<sphinx:document id="1"><name>Person One</name><age>25</age>' \
        "</sphinx:document>"
      result << "</sphinx:docset>"
      expect(xmlpipe2).to receive(:generate_schema) do
        @buffer << '<sphinx:schema><sphinx:field name="name"/><sphinx:attr ' \
          'name="age" type="int"/></sphinx:schema>'
      end
      expect(xmlpipe2).to receive(:generate_docset) do
        @buffer << '<sphinx:document id="1"><name>Person One</name>' \
          "<age>25</age></sphinx:document>"
      end
      xmlpipe2.generate!
      expect(@buffer).to eql(result)
    end
  end
end
