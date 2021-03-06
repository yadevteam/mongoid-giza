require "docile"
require "mongoid"
require "riddle"
require "mongoid/giza/configuration"
require "mongoid/giza/dynamic_index"
require "mongoid/giza/index"
require "mongoid/giza/index/common"
require "mongoid/giza/index/field"
require "mongoid/giza/index/attribute"
require "mongoid/giza/indexer"
require "mongoid/giza/models/id"
require "mongoid/giza/railtie" if defined?(Rails)
require "mongoid/giza/search"
require "mongoid/giza/version"
require "mongoid/giza/xml_pipe2"

module Mongoid
  # Module that should be included in a Mongoid::Document in order to
  #   index fields of documents of this class
  #
  # @example Creating a simple index with a full-text field (named fts) and an
  #   attribute (named attr)
  #   class Person
  #     include Mongoid::Document
  #     include Mongoid::Giza
  #
  #     field :name
  #     field :age, type: Integer
  #
  #     sphinx_index do
  #       field :name
  #       attribute :age
  #     end
  #   end
  #
  # @example Searching the previously defined index for people named John
  # between 18 and 59 years old
  #   results = Person.search do
  #     fulltext "john"
  #     with age: 18..59
  #   end
  #
  #   results.first[:Person].first # => First object that matched
  module Giza
    extend ActiveSupport::Concern

    included do
      ID.create(id: name.to_sym) unless ID.where(id: name.to_sym).count == 1
      field :_giza_id, type: Integer,
                       default: -> { ID.next(self.class.name.to_sym) }
      index({_giza_id: 1}, sparse: true, unique: true)
      @giza_configuration = Configuration.instance
      @static_sphinx_indexes = {}
      @generated_sphinx_indexes = {}
      @dynamic_sphinx_indexes = []
    end

    # Generates all the dynamic indexes defined on the class for the object
    def generate_sphinx_indexes
      self.class.dynamic_sphinx_indexes.each do |dynamic_index|
        index = dynamic_index.generate_index(self)
        self.class.generated_sphinx_indexes[index.name] = index
        self.class.giza_configuration.add_index(index, true)
      end
    end

    # :nodoc:
    module ClassMethods
      attr_reader :giza_configuration, :static_sphinx_indexes,
                  :generated_sphinx_indexes, :dynamic_sphinx_indexes

      # Class method that defines a index relative to the current class objects.
      # If an argument is given in the block then a dynamic index will be
      #   created.
      # Otherwise it will create a static index.
      #
      # @param settings [Hash] optional settings for the index and it's source
      # @param block [Proc] a block that will be evaluated on an
      #   {Mongoid::Giza::Index}
      def sphinx_index(settings = {}, &block)
        return unless block_given?
        if block.arity > 0
          add_dynamic_sphinx_index(settings, block)
        else
          add_static_sphinx_index(settings, block)
        end
      end

      # Adds an dynamic index to the class.
      # Will also automatically generate the dynamic index for each object of
      #   the class
      #
      # @param settings [Hash] settings for the index and it's source
      # @param block [Proc] a block that will be evaluated on an
      #   {Mongoid::Giza::Index}.
      #   The block receives one argument that is the current object of the
      #   class for which the index will be generated
      def add_dynamic_sphinx_index(settings, block)
        dynamic_index = DynamicIndex.new(self, settings, block)
        dynamic_sphinx_indexes << dynamic_index
        process_dynamic_sphinx_index(dynamic_index)
      end

      # Adds an static index to the class
      #
      # @param settings [Hash] settings for the index and it's source
      # @param block [Proc] a block that will be evaluated on an
      #   {Mongoid::Giza::Index}.
      def add_static_sphinx_index(settings, block)
        index = Index.new(self, settings)
        Docile.dsl_eval(index, &block)
        static_sphinx_indexes[index.name] = index
        giza_configuration.add_index(index)
      end

      # Generates the indexes from the dynamic index and
      # registers them on the class and on the configuration
      #
      # @param dynamic_index [Mongoid::Giza::DynamicIndex] the dynamic index
      #   which will generate the static indexes from
      def process_dynamic_sphinx_index(dynamic_index)
        generated = dynamic_index.generate!
        generated_sphinx_indexes.merge!(generated)
        generated.each { |_, index| giza_configuration.add_index(index, true) }
      end

      # Class method that implements a search DSL using a
      #   {Mongoid::Giza::Search} object.
      # The search will run on indexes defined on the class unless it's
      #   overwritten using {Mongoid::Giza::Search#indexes=}
      #
      # @param block [Proc] a block that will be evaluated on a
      #   {Mongoid::Giza::Search}
      #
      # @return [Hash] a Riddle result Hash containing an
      #   additional key with the name of the class.
      #   The value of this aditional key is a Mongoid::Criteria that return the
      #   actual objects of the match
      def search(&block)
        search = Search.new(giza_configuration.searchd.address,
                            giza_configuration.searchd.port,
                            sphinx_indexes_names)
        Docile.dsl_eval(search, &block)
        map_to_mongoid(search.run)
      end

      # Regenerates all dynamic indexes of the class
      def regenerate_sphinx_indexes
        giza_configuration
          .remove_generated_indexes(generated_sphinx_indexes.keys)
        generated_sphinx_indexes.clear
        dynamic_sphinx_indexes.each do |dynamic_index|
          process_dynamic_sphinx_index(dynamic_index)
        end
      end

      # Removes the generated indexes.
      #
      # @param names [Array] a list of generated index names that should be
      #   removed
      def remove_generated_sphinx_indexes(*names)
        names.each { |name| generated_sphinx_indexes.delete(name) }
        giza_configuration.remove_generated_indexes(names)
      end

      # Execute the indexing routines of the indexes defined on the class.
      # This means (re)create the sphinx configuration file and then execute the
      #   indexer program on it.
      # If no index names are supplied than all indexes defined on the class
      #   will be indexed.
      # If none of the index names supplied are on this class then nothing is
      #   indexed
      #
      # @param names [Array] a list of index names of this class that will be
      #   indexed
      def sphinx_indexer!(*names)
        if !names.empty?
          indexes_names =
            sphinx_indexes_names.select { |name| names.include?(name) }
        else
          indexes_names = sphinx_indexes_names
        end
        Indexer.instance.index!(*indexes_names) unless indexes_names.empty?
      end

      # Retrieves all the sphinx indexes defined on this class, static and
      #   dynamic
      #
      # @return [Hash] a Hash with indexes names as keys and the actual indexes
      #   as the values
      def sphinx_indexes
        static_sphinx_indexes.merge(generated_sphinx_indexes)
      end

      # Retrieves all the names of sphinx indexes defined on this class, static
      #   and dynamic
      #
      # @return [Array] an Array of names of indexes from the current class
      #   {Mongoid::Giza::Index}
      def sphinx_indexes_names
        static_sphinx_indexes.merge(generated_sphinx_indexes).keys
      end

      private

      # Creates the Mongoid::Criteria that return the objects matched by the
      #   sphinx search
      #
      # @param result [Hash] the query result created by Riddle
      # @return [Hash] the result hash with the Mongoid::Criteria on the indexed
      #   class' name key
      def map_to_mongoid(result)
        result[name.to_sym] =
          self.in(_giza_id: result[:matches].map { |match| match[:doc] })
        result
      end
    end
  end
end
