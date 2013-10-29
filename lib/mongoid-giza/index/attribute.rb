module Mongoid
  module Giza
    class Index
      # Represents an Sphinx index attribute
      class Attribute

        # Defines the array of currently supported Sphix attribute types
        TYPES = [
          :uint, :bool, :bigint, :timestamp, :str2ordinal,
          :float, :multi, :string, :json, :str2wordcount
        ]

        attr_accessor :name, :type, :block

        # Creates a new attribute with name, type and an optional block
        #
        # If a block is given then it will be evaluated for each instance of the class being indexed
        # and the resulting value will be the attribute value.
        # Otherwise the attribute value will be the value of the corresponding object field
        #
        # Parameters::
        #   * [ +Symbol+ +name+ ] the name of the attribute
        #   * [ +Symbol+ +type+ ] the type of the attribute. Must be one of the types defined in +Mongoid+::+Giza+::+Attribute+::+types+
        def initialize(name, type, &block)
          raise TypeError,
            "attribute type not supported. " \
            "It must be one of the following: " \
            "#{Mongoid::Giza::Index::Attribute::TYPES.join(", ")}" unless Mongoid::Giza::Index::Attribute::TYPES.include? type
          @name = name
          @type = type
          @block = block
        end
      end
    end
  end
end
