module Mongoid
  module Giza

    # Routines related to creating the defined indexes in sphinx
    module Indexer
      @configuration = Mongoid::Giza::Configuration.instance

      class << self
        def controller
          @controller ||= Riddle::Controller.new(@configuration, @configuration.file.output_path)
        end

        # Creates the sphinx configuration file then executes the indexer on it
        def index!
          Mongoid::Giza::Instance.indexes.each_value { |index| @configuration.add_index(index) }
          @configuration.render
          controller.index(verbose: true)
        end
      end
    end
  end
end
