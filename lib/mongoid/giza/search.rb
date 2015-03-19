module Mongoid
  module Giza
    # Executes queries on Sphinx
    class Search
      attr_accessor :indexes
      attr_reader :client

      # Creates a new search
      #
      # @param host [String] the host address of sphinxd
      # @param port [Fixnum] the TCP port of sphinxd
      # @param names [Array] an optional array defining the indexes that the
      #   search will run on.
      #   Defaults to "[]" which means all indexes
      def initialize(host, port, names = [])
        @client = Riddle::Client.new(host, port)
        @indexes = names
      end

      # Sets the search criteria on full-text fields
      #
      # @param query [String] a sphinx query string based on the current
      #   {http://sphinxsearch.com/docs/current.html#matching-modes
      #   matching mode}
      def fulltext(query)
        index = indexes.length > 0 ? indexes.join(" ") : "*"
        @client.append_query(query, index)
      end

      # Sets a filter based on an attribute.
      # Only documents that the attribute value matches will be returned from
      #   the search
      #
      # @param attribute [Symbol] the attribute name to set the filter
      # @param value [Fixnum, Float, Range] the value (or values) that the
      #   attribute must match
      def with(attribute, value)
        @client.filters << Riddle::Client::Filter.new(attribute.to_s, value,
                                                      false)
      end

      # Excludes from the search documents that the attribute value matches
      #
      # @param attribute [Symbol] the attribute name
      # @param value [Fixnum, Float, Range] the value (or values) that the
      #   attribute must match
      def without(attribute, value)
        @client.filters << Riddle::Client::Filter.new(attribute.to_s, value,
                                                      true)
      end

      # Sets the order in which the results will be returned
      #
      # @param attribute [Symbol] the attribute used for sorting
      # @param order [Symbol] the order of the sorting. Valid values are :asc
      #   and :desc
      def order_by(attribute, order)
        @client.sort_by = "#{attribute} #{order.to_s.upcase}"
      end

      # Executes the configured queries
      #
      # @return [Array] an Array of Hashes as specified by Riddle::Response
      def run
        @client.run
      end

      # Checks for methods on Riddle::Client
      #
      # @param method [Symbol, String] the method name that will be checked on
      #   Riddle::Client
      #
      # @return [TrueClass, FalseClass] true if either Riddle::Client or
      #   Mongoid::Giza::Search respond to the method
      def respond_to?(method)
        @client.respond_to?("#{method}=") || super
      end

      # Dynamically dispatches the method call to Riddle::Client if the method
      #   is defined in it
      #
      # @param method [Symbol, String] the method name that will be called on
      #   Riddle::Client
      # @param args [Array] an argument list that will also be forwarded to the
      #   Riddle::Client method
      #
      # @return [Object] the return value of the Riddle::Client method
      #
      # @raise [NoMethodError] if the method is also missing on Riddle::Client
      def method_missing(method, *args)
        super if !respond_to?(method)
        @client.send "#{method}=", *args
      end
    end
  end
end
