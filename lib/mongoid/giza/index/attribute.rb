module Mongoid
  module Giza
    class Index
      # Represents a Sphinx index attribute
      class Attribute
        include Common

        # Defines the array of currently supported Sphix attribute types
        TYPES = [
          :uint, :bool, :bigint, :timestamp, :float,
          :multi, :multi_64, :string, :json
        ]

        attr_accessor :name, :type, :default, :bits, :block

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
        def initialize(name, type, options = {}, &block)
          fail TypeError,
               "Attribute type not supported. " \
               "It must be one of the following: " \
               "#{TYPES.join(', ')}" unless TYPES.include? type
          @name = normalize(name)
          @type = type
          @block = block
          @default = options[:default]
          @bits = options[:bits] if type == :uint
        end
      end
    end
  end
end
