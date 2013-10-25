module Mongoid
  module Giza
    # Represents an Sphinx index attribute
    class Attribute
      class << self;

        # Defines the array of currently supported Sphix attribute types
        def types
          [:uint, :bool, :bigint, :timestamp, :str2ordinal,
            :float, :multi, :string, :json, :str2wordcount]
        end
      end

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
          "#{self.class.types.join(", ")}" unless self.class.types.include? type
        @name = name
        @type = type
        @block = block
      end
    end
  end
end
