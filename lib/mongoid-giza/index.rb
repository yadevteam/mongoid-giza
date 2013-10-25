module Mongoid
  module Giza
    class Index
      attr_accessor :fields

      def initialize
        @fields = []
      end
    end
  end
end
