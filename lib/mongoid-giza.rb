require "mongoid"
require "mongoid-giza/config"
require "mongoid-giza/index"
require "mongoid-giza/index/field"
require "mongoid-giza/index/attribute"
require "mongoid-giza/instance"
require "mongoid-giza/version"

module Mongoid
  ##
  # Module that should be included in a Mongoid::Document in order to
  # index fields of documents of this class
  #
  # @example Creating a simple index with a full-text field (named fts) and an attribute (named attr)
  #   class Person
  #     include Mongoid::Document
  #     include Mongoid::Giza
  #
  #     field :name
  #     field :age, type: Integer
  #
  #     search_index do
  #       field :name
  #       attribute :age
  #     end
  #   end
  module Giza
    extend ActiveSupport::Concern

    module ClassMethods
      ##
      # Class method that defines a index relative to the current model's documents
      #
      # @param block [Proc] a block that will be evaluated on an {Mongoid::Giza::Index}
      #
      # @return [Mongoid::Giza::Index] the new index
      def search_index(&block)
        index = Index.new
        index.instance_eval(&block)
        Mongoid::Giza::Instance.indexes[index.name] = index
        index
      end
    end
  end
end
