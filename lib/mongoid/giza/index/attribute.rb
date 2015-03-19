module Mongoid
  module Giza
    class Index
      # Represents a Sphinx index attribute
      class Attribute
        # Defines the array of currently supported Sphix attribute types
        TYPES = [
          :int, :bool, :bigint, :timestamp, :str2ordinal,
          :float, :multi, :string, :json, :str2wordcount
        ]

        attr_accessor :name, :type, :block

        # Creates a new attribute with name, type and an optional block
        #
        # If a block is given then it will be evaluated for each instance of the
        #   class being indexed and the resulting value will be the attribute
        #   value.
        # Otherwise the attribute value will be the value of the corresponding
        #   object field
        #
        # @param name [Symbol] the name of the attribute
        # @param type [Symbol] the type of the attribute. Must be one of the
        #   types defined in {Mongoid::Giza::Index::Attribute::TYPES}
        # @param block [Proc] an optional block to be evaluated at the scope of
        #   the document on index creation
        #
        # @raise [TypeError] if the type is not valid. (see
        #   {Mongoid::Giza::Index::Attribute::TYPES})
        def initialize(name, type, &block)
          raise TypeError,
            "attribute type not supported. " \
            "It must be one of the following: " \
            "#{Mongoid::Giza::Index::Attribute::TYPES.join(", ")}" unless Mongoid::Giza::Index::Attribute::TYPES.include? type
          @name = name.to_s.mb_chars.downcase.to_sym
          @type = type
          @block = block
        end
      end
    end
  end
end
