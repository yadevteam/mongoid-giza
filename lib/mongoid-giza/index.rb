module Mongoid
  module Giza
    class Index
      attr_accessor :klass, :fields, :attributes

      def initialize(klass)
        @klass = klass
        @fields = []
        @attributes = []
      end

      def field(name, &block)
        @fields << Mongoid::Giza::Field.new(name, block)
      end
    end
  end
end
