module Mongoid
  module Giza
    class DynamicIndex
      attr_reader :klass, :settings, :block

      def initialize(klass, settings, block)
        @klass = klass
        @settings = settings
        @block = block
      end

      def generate!
        indexes = {}
        klass.all.each do |object|
          index = Mongoid::Giza::Index.new(klass, settings)
          Docile.dsl_eval(index, object, &block)
          indexes[index.name] = index
        end
        indexes
      end
    end
  end
end
