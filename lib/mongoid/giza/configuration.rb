require "riddle"
require "yaml"

module Mongoid
  module Giza
    ##
    # Holds the configuration of the module
    class Configuration < Riddle::Configuration
      include Singleton
      ##
      # Loads a YAML file with settings defined.
      # Settings that are not recognized are ignored
      #
      # @param path [String] path to the YAML file which contains the settings defined
      def load(path)
        YAML.load(File.open(path).read).each do |section_name, settings|
          section = instance_variable_get("@#{section_name}")
          if !section.nil?
            settings.each do |setting, value|
              method = "#{setting}="
              section.send(method, value) if section.respond_to?(method)
            end
          end
        end
      end
      ##
      # Adds an index to the configuration file
      #
      # @param index [Mongoid::Giza::Index] the index to generate the configuration from
      def add_index(index)
        source = Riddle::Configuration::XMLSource.new(index.name, :xmlpipe2)
        riddle_index = Riddle::Configuration::Index.new(index.name, source)
        index.settings.each do |setting, value|
          method = "#{setting}="
          riddle_index.send(method, value) if riddle_index.respond_to?(method)
        end
        @indices << riddle_index
      end
    end
  end
end
