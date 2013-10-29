require "mongoid"
require "mongoid-giza/version"
require "mongoid-giza/index"
require "mongoid-giza/index/field"
require "mongoid-giza/index/attribute"

module Mongoid
  module Giza
    extend ActiveSupport::Concern

    module ClassMethods
      def search_index(&block)
        index = Index.new
        index.instance_eval(&block)
        index
      end
    end
  end
end
