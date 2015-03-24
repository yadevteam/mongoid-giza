module Mongoid
  module Giza
    # MongoDB counter collection to generate ids compatible with sphinx
    class ID
      include Mongoid::Document

      field :_id, type: Symbol
      field :seq, type: Integer, default: 0

      class << self
        # Gets the next id in the sequence to assign to an object
        #
        # @param klass [Symbol] the name of the class which next id will be
        #   retrived for
        #
        # @return [Integer] the next id in the sequence
        def next(klass)
          giza_id = where(id: klass).find_and_modify({"$inc" => {seq: 1}},
                                                     new: true)
          giza_id.seq
        end
      end
    end
  end
end
