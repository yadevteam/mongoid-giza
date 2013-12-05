require "docile"
require "mongoid"
require "riddle"
require "mongoid/giza/configuration"
require "mongoid/giza/index"
require "mongoid/giza/index/field"
require "mongoid/giza/index/attribute"
require "mongoid/giza/indexer"
require "mongoid/giza/instance"
require "mongoid/giza/models/giza_id"
require "mongoid/giza/railtie" if defined?(Rails)
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

    included do
      Mongoid::Giza::GizaID.create(id: name.to_sym)
      @giza_configuration = Mongoid::Giza::Configuration.instance
    end

    # Retrives the sphinx compatible id of the object.
    # If the id does not exists yet, it will be generated
    #
    # @return [Integer] the object's integer id generated by Giza
    def giza_id
      set(:giza_id, GizaID.next_id(self.class.name.to_sym)) if self[:giza_id].nil?
      self[:giza_id]
    end

    module ClassMethods

      # Class method that defines a index relative to the current model's documents
      #
      # @param block [Proc] a block that will be evaluated on an {Mongoid::Giza::Index}
      def search_index(settings = {}, &block)
        index = Index.new(self, settings)
        Docile.dsl_eval(index, &block)
        sphinx_indexes[index.name] = index
        @giza_configuration.add_index(index)
      end

      # Class method that implements a search DSL using a {Mongoid::Giza::Search} object.
      # The search will run on indexes defined on the class unless it's overwritten using {Mongoid::Giza::Search#indexes=}
      #
      # @param block [Proc] a block that will be evaluated on a {Mongoid::Giza::Search}
      #
      # @return [Array] an Array with Riddle result hashes containing an additional key with the name of the class.
      #   The value of this aditional key is a Mongoid::Criteria that return the actual objects of the match
      def search(&block)
        search = Mongoid::Giza::Search.new(@giza_configuration.searchd.address,
          @giza_configuration.searchd.port,
          *sphinx_indexes.values.map(&:name))
        Docile.dsl_eval(search, &block)
        results = search.run
        results.each { |result| result[name.to_sym] = self.in(giza_id: result[:matches].map { |match| match[:doc] }) }
      end

      # Retrieves all the sphinx indexes defined on this class
      #
      # @return [Array] an Array of the current class {Mongoid::Giza::Index}
      def sphinx_indexes
        @sphinx_indexes ||= {}
      end

      # Execute the indexing routines of the indexes defined on the class.
      # This means (re)create the sphinx configuration file and then execute the indexer program on it.
      def sphinx_indexer!(*indexes_names)
        indexes = indexes_names.length > 0 ?
          sphinx_indexes.values.select { |index| indexes_names.include? index.name } :
          sphinx_indexes.values
        Mongoid::Giza::Indexer.instance.index!(*indexes.map(&:name)) if indexes.length > 0
      end
    end
  end
end
