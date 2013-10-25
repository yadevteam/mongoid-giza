module Mongoid
  module Giza
    # Represents a Sphinx index
    class Index
      class << self;

        # Returns a hash in which each key is a class accepted by +Mongoid+
        # and its value is a compatible Sphix attribute type
        def types_map
          {
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
        end
      end

      attr_accessor :klass, :settings, :fields, :attributes

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
        @fields = []
        @attributes = []
      end

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
        @fields << Mongoid::Giza::Field.new(name, block)
      end

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
          type = field.nil? ? self.class.types_map.values.first :
            self.class.types_map[field.type] || self.class.types_map.values.first
        end
        @attributes << Mongoid::Giza::Attribute.new(name, type, block)
      end
    end
  end
end
