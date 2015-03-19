module Mongoid
  module Giza
    # Defines a dynamic index which is used to generate a index for each object
    #   of the class
    class DynamicIndex
      attr_reader :klass, :settings, :block

      # Creates a new dynamic index for the supplied class
      #
      # @param klass [Class] a class which each object will generate an
      #   {Mongoid::Giza::Index}
      #   after the evaluation of the block
      # @param settings [Hash] a hash of settings to be defined on every
      #   generated index
      # @param block [Proc] the routine that will be evaluated for each object
      #   from the class
      def initialize(klass, settings, block)
        @klass = klass
        @settings = settings
        @block = block
      end

      # Generates indexes for every object of the class.
      # The name of the index is unique so in case of a name collision,
      # the last index to be generated is the one that will persist
      #
      # @return [Hash<Symbol, Mongoid::Giza::Index>] an hash with every key
      #   being the index name
      #   and the value the index itself
      def generate!
        indexes = {}
        klass.all.each do |object|
          index = generate_index(object)
          indexes[index.name] = index if !index.nil?
        end
        indexes
      end

      # Generates the index for the object passed as parameter.
      # It is only generated if the object's class is the class or a subclass of
      #   the index's class
      #
      # @param object [Mongoid::Document] the object which the index block wil
      #   be evaluated for
      #
      # @return [Mongoid::Giza::Index, NilClass] the resulting index from the
      #   evaluation or nil if the object's class is not the index's class or a
      #   subclass of it
      def generate_index(object)
        if object.is_a?(klass)
          index = Mongoid::Giza::Index.new(klass, settings)
          Docile.dsl_eval(index, object, &block)
        end
      end
    end
  end
end
