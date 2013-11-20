module Mongoid
  module Giza

    # Holds the defined indexes
    module Instance
      class << self

        # Retrieves the collection of {Mongoid::Giza::Index indexes} defined so far
        #
        # @return [Hash] all {Mongoid::Giza::Index indexes}
        def indexes
          @indexes ||= {}
        end
      end
    end
  end
end
