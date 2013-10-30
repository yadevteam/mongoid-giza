module Mongoid # :nodoc:
  module Giza
    ##
    # Represents a Sphinx index
    class Index
      ##
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
        Moped::BSON::ObjectId => :string,
        ActiveSupport::TimeWithZone => :timestamp,
      }

      attr_accessor :klass, :settings, :fields, :attributes
      ##
      # Creates a new index with a class, which should include Mongoid::Document, and an optional settings hash.
      #
      # Note that no validations are made on class, so classes that behave like Mongoid::Document should be fine.
      #
      # Parameters::
      #   * [ Class klass ] the class whose objects will be indexed
      #   * [ Hash settings ] an optional settings hash to be forwarded to Riddle
      def initialize(klass, settings={})
        @klass = klass
        @settings = settings
        @name = @klass.name.to_sym
        @fields = []
        @attributes = []
      end
      ##
      # Adds a fulltext search field to the index with the corresponding name.
      #
      # If a block is given then it will be evaluated for each instance of the class being indexed
      # and the resulting string will be the field value.
      # Otherwise the field value will be the value of the corresponding object field
      #
      # Parameters::
      #   * [ +Symbol+ +name+ ] the name of the field
      #   * [ +Proc+ +block+ ] an optional block to be evaluated
      def field(name, &block)
        @fields << Mongoid::Giza::Index::Field.new(name, block)
      end
      ##
      # Adds an attribute to the index with the corresponding name.
      #
      # If a type is not given then it will try to fetch the type of the corresponding class field,
      # falling back to +:string+
      #
      # If a block is given then it will be evaluated for each instance of the class being indexed
      # and the resulting value will be the attribute value.
      # Otherwise the attribute value will be the value of the corresponding object field
      #
      # Parameters::
      #   * [ +Symbol+ +name+ ] the name of the attribute
      #   * [ +Symbol+ +type+ ] an optional attribute type
      #   * [ +Proc+ +block+ ] an optional block to be evaluated
      def attribute(name, type=nil, &block)
        if type.nil?
          field = @klass.fields[name.to_s]
          type = field.nil? ? Mongoid::Giza::Index::TYPES_MAP.values.first :
            Mongoid::Giza::Index::TYPES_MAP[field.type] || Mongoid::Giza::Index::TYPES_MAP.values.first
        end
        @attributes << Mongoid::Giza::Index::Attribute.new(name, type, block)
      end
      ##
      # Retrieves and optionally sets the index name
      #
      # Parameters::
      #   * [ +Symbol+ +new_name+ ] an optional new name for the index
      #
      # Return value::
      #   The name of the index
      def name(new_name=nil)
        if !new_name.nil?
          @name = new_name.to_sym
        end
        @name
      end
    end
  end
end
