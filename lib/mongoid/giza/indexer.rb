module Mongoid
  module Giza

    # Routines related to creating the defined indexes in sphinx
    module Indexer
      @configuration = Mongoid::Giza::Configuration.instance
      @controller = Riddle::Controller.new(@configuration, @configuration.file.output_path)

      class << self
        attr_reader :controller

        # Creates the sphinx configuration file then executes the indexer on it
        def index!
          Mongoid::Giza::Instance.indexes.each_value { |index| @configuration.add_index(index) }
          @configuration.render
          @controller.index
        end
      end
    end
  end
end
