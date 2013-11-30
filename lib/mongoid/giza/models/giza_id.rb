module Mongoid
  module Giza

    # MongoDB counter collection to generate ids compatible with sphinx
    class GizaID
      include Mongoid::Document

      field :_id, type: Symbol
      field :seq, type: Integer, default: 0

      attr_accessible :id

      class << self

        # Gets the next id in the sequence to assign to an object
        #
        # @param model [Symbol] the name of the model which next id will be retrived for
        #
        # @return [Integer] the next id in the sequence
        def next_id(model)
          giza_id = where(id: model).find_and_modify({"$inc" => {seq: 1}}, new: true)
          giza_id.seq
        end
      end
    end
  end
end
