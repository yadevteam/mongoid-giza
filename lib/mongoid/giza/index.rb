module Mongoid
  module Giza
    # Represents a Sphinx index
    class Index
      # Hash in which each key is a class accepted by +Mongoid+
      # and its value is a compatible Sphix attribute type
      TYPES_MAP = {
        Regexp => :string,
        String => :string,
        Symbol => :string,
        Boolean => :bool,
        Integer => :bigint,
        Date => :timestamp,
        DateTime => :timestamp,
        Time => :timestamp,
        BigDecimal => :float,
        Float => :float,
        Array => :multi,
        Range => :multi,
        Hash => :json,
        BSON::ObjectId => :string,
        ActiveSupport::TimeWithZone => :timestamp
      }

      attr_accessor :klass, :settings, :fields, :attributes

      # Creates a new index with a class, which should include
      #   Mongoid::Document, and an optional settings hash.
      #
      # Note that no validations are made on class, so classes that behave like
      #   Mongoid::Document should be fine.
      #
      # @param klass [Class] the class whose objects will be indexed
      # @param settings [Hash] an optional settings hash to be forwarded to
      #   Riddle
      def initialize(klass, settings = {})
        @klass = klass
        @settings = settings
        @name = @klass.name.to_sym
        @criteria = klass.all
        @fields = []
        @attributes = []
      end

      # Adds a full-text field to the index with the corresponding name
      #
      # If a block is given then it will be evaluated for each instance of the
      #   class being indexed and the resulting string will be the field value.
      # Otherwise the field value will be the value of the corresponding object
      #   field
      #
      # @param name [Symbol] the name of the field
      # @param options [Hash] options for the field.
      # @option options [TrueClass, FalseClass] :attribute whether the field
      #   will also be a attribute or not (see
      #   {Mongoid::Giza::Index::Field#initialize})
      # @param block [Proc] an optional block to be evaluated at the scope of
      #   the document on index creation
      def field(name, options = {}, &block)
        attribute = options[:attribute]
        @fields << Field.new(name, attribute, &block)
      end

      # Adds an attribute to the index with the corresponding name.
      #
      # If a type is not given then it will try to fetch the type of the
      #   corresponding class field, falling back to :string
      #
      # If a block is given then it will be evaluated for each instance of the
      #   class being indexed and the resulting value will be the attribute
      #   value.
      # Otherwise the attribute value will be the value of the corresponding
      #   object field
      #
      # @param name [Symbol] the name of the attribute
      # @param type [Symbol] an optional attribute type
      # @param block [Proc] an optional block to be evaluated at the scope of
      #   the document on index creation
      def attribute(name, type = nil, options = {}, &block)
        unless type
          field = @klass.fields[name.to_s]
          if field
            type = TYPES_MAP[field.type] || :string
          else
            type = :string
          end
        end
        @attributes << Attribute.new(name, type, options, &block)
      end

      # Retrieves and optionally sets the index name
      #
      # @param new_name [Symbol, String] an optional new name for the index
      #
      # @return [Symbol] The name of the index
      def name(new_name = nil)
        @name = new_name.to_sym if new_name
        @name
      end

      # Defines the Mongoid::Criteria that will be used to retrive objects when
      #   indexing.
      # Use this to filter what objects from the class will be indexed.
      # When an index is created the criteria is defined as class.all
      #
      # @param new_criteria [Mongoid::Criteria] the criteria to be used
      def criteria(new_criteria = nil)
        @criteria = new_criteria || @criteria
      end

      # Generates a XML document according to the XMLPipe2 specification from
      #   Sphinx
      #
      # @param buffer [#<<] any IO object that supports appending content using
      #   <<
      def xmlpipe2(buffer)
        Mongoid::Giza::XMLPipe2.new(self, buffer).generate!
      end
    end
  end
end
