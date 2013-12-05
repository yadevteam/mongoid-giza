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

      # Creates the sphinx configuration file then executes the indexer on it
      def index!(*indexes)
        @configuration.render
        @controller.index(*indexes, verbose: true)
      end
    end
  end
end
