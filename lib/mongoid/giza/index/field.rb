module Mongoid
  module Giza
    class Index
      # Represents a Sphinx indexed field
      class Field
        include Common

        attr_accessor :attribute, :block
        attr_reader :name

        # Creates a full-text field with a name and an optional block
        #
        # If a block is given then it will be evaluated for each instance of the
        #   class being indexed
        # and the resulting string will be the field value.
        # Otherwise the field value will be the value of the corresponding
        #   object field
        #
        # @param name [Symbol] the name of the field
        # @param attribute [TrueClass, FalseClass] whether this field will also
        #   be stored as an string attribute
        # @param block [Proc] an optional block to be evaluated at the scope of
        #   the document on index creation
        def initialize(name, attribute = nil, &block)
          @name = normalize(name)
          @attribute = attribute
          @block = block
        end
      end
    end
  end
end
