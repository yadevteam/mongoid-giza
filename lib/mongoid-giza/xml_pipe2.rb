require "builder"

module Mongoid
  module Giza
    class XMLPipe2
      ##
      # Creates a new XMLPipe2 object based on the specified index and that will write to the specified buffer.
      # Note that the actual XML will be generated only when {#generate!} is called
      #
      # @param index [Mongoid::Giza::Index] the index which will be used to generate the data
      # @param buffer any object that supports the method <<
      def initialize(index, buffer)
        @index = index
        @xml = Builder::XmlMarkup.new(target: buffer)
      end
      ##
      # Generates a XML document with the {http://sphinxsearch.com/docs/current.html#xmlpipe2 xmlpipe2 specification}.
      # The buffer passed on object creation will contain the XML
      def generate!
        @xml.instruct! :xml, version: "1.0", encoding: "utf-8"
        @xml.sphinx :docset do |docset|
          generate_schema
          generate_docset
        end
      end
      ##
      # Generates the schema part of the XML document.
      # Used internally by {#generate!} so you should never need to call it directly
      def generate_schema
        @xml.sphinx :schema do |schema|
          @index.fields.each do |field|
            attrs = {name: field.name}
            attrs[:attr] = :string if field.attribute
            schema.sphinx :field, attrs
          end
          @index.attributes.each { |attribute| schema.sphinx :attr, name: attribute.name, type: attribute.type }
        end
      end
      ##
      # Generates the content part of the XML document.
      # Used internally by {#generate!} so you should never need to call it directly
      def generate_docset
        @index.klass.collection.find.each do |object|
          @xml.sphinx :document, id: object["giza_id"] do |document|
            @index.fields.each { |field| document.tag! field.name, object[field.name.to_s].to_s }
            @index.attributes.each { |attribute| document.tag! attribute.name, object[attribute.name.to_s].to_s }
          end
        end
      end
    end
  end
end