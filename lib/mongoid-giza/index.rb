module Mongoid
  module Giza
    class Index
      class << self;
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

      attr_accessor :klass, :fields, :attributes

      def initialize(klass)
        @klass = klass
        @fields = []
        @attributes = []
      end

      def field(name, &block)
        @fields << Mongoid::Giza::Field.new(name, block)
      end

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
