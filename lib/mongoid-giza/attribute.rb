module Mongoid
  module Giza
    class Attribute
      class << self;
        def types
          [:uint, :bool, :bigint, :timestamp, :str2ordinal,
            :float, :multi, :string, :json, :str2wordcount]
        end
      end

      attr_accessor :name, :type, :block

      def initialize(name, type, &block)
        raise TypeError,
          "attribute type not supported. " \
          "It must be one of the following: " \
          "#{self.class.types.join(", ")}" unless self.class.types.include? type
        @name = name
        @type = type
        @block = block
      end
    end
  end
end
