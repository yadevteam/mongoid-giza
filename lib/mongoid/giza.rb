require "mongoid"
require "riddle"
require "mongoid/giza/configuration"
require "mongoid/giza/index"
require "mongoid/giza/index/field"
require "mongoid/giza/index/attribute"
require "mongoid/giza/instance"
require "mongoid/giza/search"
require "mongoid/giza/version"
require "mongoid/giza/xml_pipe2"

module Mongoid

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
  #
  # @example Searching the previously defined index for people named John between 18 and 59 years old
  #   results = Person.search do
  #     fulltext "john"
  #     with age: 18..59
  #   end
  #
  #   results[:Person].first # => First object that matched
  module Giza
    extend ActiveSupport::Concern

    module ClassMethods

      # Class method that defines a index relative to the current model's documents
      #
      # @param block [Proc] a block that will be evaluated on an {Mongoid::Giza::Index}
      def search_index(&block)
        index = Index.new(self)
        index.instance_eval(&block)
        Mongoid::Giza::Instance.indexes[index.name] = index
        (@sphinx_indexes ||= []) << index.name
      end

      # Class method that implements a search DSL using a {Mongoid::Giza::Search} object.
      # The search will run on indexes defined on the class unless it's overwritten using {Mongoid::Giza::Search#indexes=}
      #
      # @param block [Proc] a block that will be evaluated on a {Mongoid::Giza::Search}
      #
      # @return [Hash, Array] a Riddle result hash containing an additional key with the name of the class
      #   if only one {Mongoid::Giza::Search#fulltext} query was defined.
      #   If two or more were defined then returns an Array containing results Hashes as described above,
      #   one element for each {Mongoid::Giza::Search#fulltext} query
      def search(&block)
        config = Mongoid::Giza::Configuration.instance
        search = Mongoid::Giza::Search.new(config.searchd.address, config.searchd.port)
        search.indexes = @sphinx_indexes.join(" ")
        search.instance_eval(&block)
        results = search.run
        results.each { |result| result[name.to_sym] = self.in(giza_id: result[:matches].map { |match| match[:doc] }) }
        results.length > 1 ? results : results.first
      end
    end
  end
end
