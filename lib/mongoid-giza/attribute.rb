module Mongoid
  module Giza
    class Attribute
      attr_accessor :name, :type, :block

      def initialize(name, type, &block)
        @name = name
        @type = type
        @block = block
      end
    end
  end
end
