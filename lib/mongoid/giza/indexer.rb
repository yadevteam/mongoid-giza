module Mongoid
  module Giza

    # Routines related to creating the defined indexes in sphinx
    class Indexer
      include Singleton

      # Creates the Indexer instance
      def initialize
        @configuration = Mongoid::Giza::Configuration.instance
        @controller = Riddle::Controller.new(@configuration, @configuration.file.output_path)
      end

      # Index everything, regenerating all dynamic indexes from all classes
      def full_index!
        @configuration.clear_generated_indexes
        giza_classes.each { |klass| klass.regenerate_dynamic_sphinx_indexes }
        @configuration.render
        index!
      end

      # Executes the sphinx indexer
      #
      # @param indexes [Array<Symbol>] name of the indexes that should be indexed.
      #   If not provided all indexes from the configuration file are indexed
      def index!(*indexes)
        @controller.index(*indexes, verbose: true)
      end

      # @return [Array<Class>] all Mongoid models that include the {Mongoid::Giza} module
      def giza_classes
        Mongoid.models.select { |model| model.include?(Mongoid::Giza) }
      end
    end
  end
end
