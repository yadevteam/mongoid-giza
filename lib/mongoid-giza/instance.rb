module Mongoid
  module Giza
    module Instance
      class << self
        def indexes
          @indexes ||= {}
        end
      end
    end
  end
end
