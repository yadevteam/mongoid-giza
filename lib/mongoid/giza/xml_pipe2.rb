require "builder"

module Mongoid
  module Giza
    # Represents the xmlpipe2 data source
    class XMLPipe2
      # Creates a new XMLPipe2 object based on the specified index and that will
      #   write to the specified buffer.
      # Note that the actual XML will be generated only when {#generate!} is
      #   called
      #
      # @param index [Mongoid::Giza::Index] the index which will be used to
      #   generate the data
      # @param buffer any object that supports the method <<
      def initialize(index, buffer)
        @index = index
        @xml = Builder::XmlMarkup.new(target: buffer)
      end

      # Generates a XML document with the
      #   {http://sphinxsearch.com/docs/current.html#xmlpipe2
      #   xmlpipe2 specification}.
      # The buffer passed on object creation will contain the XML
      def generate!
        @xml.instruct! :xml, version: "1.0", encoding: "utf-8"
        @xml.sphinx :docset do
          generate_schema
          generate_docset
        end
      end

      # Generates the schema part of the XML document.
      # Used internally by {#generate!} so you should never need to call it
      #   directly
      def generate_schema
        @xml.sphinx :schema do |schema|
          @index.fields.each do |field|
            schema.sphinx :field, field_attrs(field)
          end
          @index.attributes.each do |attribute|
            schema.sphinx :attr, attribute_attrs(attribute)
          end
        end
      end

      # Returns a Hash of the field's attributes
      #
      # @return [Hash] The field's attributes
      def field_attrs(field)
        attrs = {name: field.name}
        attrs[:attr] = :string if field.attribute
        attrs
      end

      # Returns a Hash of the attribute's attributes
      #
      # @return [Hash] The attribute's attributes
      def attribute_attrs(attribute)
        attrs = {name: attribute.name, type: attribute.type}
        attrs[:default] = attribute.default if attribute.default
        attrs[:bits] = attribute.bits if attribute.bits
        attrs
      end

      # Generates the content part of the XML document.
      # Used internally by {#generate!} so you should never need to call it
      #   directly
      def generate_docset
        @index.criteria.each do |object|
          @xml.sphinx :document, id: object._giza_id do
            generate_doc_tags(@index.fields, object)
            generate_doc_tags(@index.attributes, object)
          end
        end
      end

      # Generates the tags with the content to be indexed of every field or
      #   attribute.
      # Used internally by {#generate_docset} so you should never need to call
      #   it directly
      #
      # @param contents [Array] list of fields or attributes to generate the
      #   tags for
      # @param object [Object] the object being indexed
      def generate_doc_tags(contents, object)
        contents.each do |content|
          if content.block.nil?
            @xml.tag! content.name, object[content.name]
          else
            @xml.tag! content.name, content.block.call(object)
          end
        end
      end
    end
  end
end
