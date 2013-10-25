module Mongoid
  module Giza
    class Index
      attr_accessor :fields, :attributes

      def initialize
        @fields = []
        @attributes = []
      end

      def field(name, &block)
        @fields << Mongoid::Giza::Field.new(name, block)
      end
    end
  end
end
