require "mongoid"
require "mongoid-giza/version"
require "mongoid-giza/index"
require "mongoid-giza/instance"
require "mongoid-giza/index/field"
require "mongoid-giza/index/attribute"

module Mongoid # :nodoc:
  ##
  # Module that should be included in a Mongoid::Document in order to
  # index fields of documents of this class
  #
  # Examples::
  #  Creating a simple index with a fulltext search field (named :+fts+) and an attribute (named :+attr+)
  #   class C
  #     include Mongoid::Document
  #     include Mongoid::Giza
  #     field :fts
  #     field :attr, type: Integer
  #     search_index do
  #       field :fts
  #       attribute :attr
  #     end
  #   end
  module Giza
    extend ActiveSupport::Concern

    module ClassMethods
      ##
      # Class method that defines a index relative to the current model's documents
      #
      # Parameters::
      #   * [ +Proc+ +block+ ] a block that will be evaluated on a +Mongoid+::+Giza+::+Index+
      #
      # Return value::
      #   The new index
      def search_index(&block)
        index = Index.new
        index.instance_eval(&block)
        Mongoid::Giza::Instance.indexes[index.name] = index
        index
      end
    end
  end
end
