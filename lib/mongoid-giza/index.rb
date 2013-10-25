module Mongoid
  module Giza
    class Index
      attr_accessor :fields, :attributes

      def initialize
        @fields = []
        @attributes = []
      end
    end
  end
end
