module Mongoid
  module Giza
    ##
    # Holds the defined indexes
    module Instance
      class << self
        ##
        # Returns the collection of indexes defined so far
        def indexes
          @indexes ||= {}
        end
      end
    end
  end
end
