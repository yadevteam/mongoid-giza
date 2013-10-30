module Mongoid # :nodoc:
  module Giza
    class Index
      # Represents a Sphinx index fulltext search field
      class Field
        attr_accessor :name, :block

        # Creates a fulltext search field with a name and an optional block
        #
        # If a block is given then it will be evaluated for each instance of the class being indexed
        # and the resulting string will be the field value.
        # Otherwise the field value will be the value of the corresponding object field
        #
        # Parameters::
        #   * [ +Symbol+ +name+ ] the name of the field
        #   * [ +Proc+ +block+ ] an optional block to be evaluated
        def initialize(name, &block)
          @name = name
          @block = block
        end
      end
    end
  end
end
