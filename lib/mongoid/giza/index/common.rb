module Mongoid
  module Giza
    class Index
      # Common routines to fields and attributes
      module Common
        extend ActiveSupport::Concern

        # Replaces all non-alphabetical characters and converts to lower case
        #
        # @param s [Symbol, String] symbol or string to be normalized
        #
        # @return [Symbol] the normalized symbol
        def normalize(s)
          s.to_s.gsub(/[^[:alpha:]_-]/, "-").mb_chars.downcase.to_sym
        end
      end
    end
  end
end
