require "yaml"
require "ostruct"

module Mongoid
  module Giza

    # Holds the configuration of the module
    class Configuration < Riddle::Configuration
      include Singleton

      attr_reader :source, :index, :file

      # Creates the configuration instance
      def initialize
        super
        @source = Riddle::Configuration::XMLSource.new(:source, :xmlpipe2)
        @index = Riddle::Configuration::Index.new(:index, @source)
        @file = OpenStruct.new
        @file.output_path = "./sphinx.conf"
      end

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

      # Adds an index to the configuration file
      #
      # @param index [Mongoid::Giza::Index] the index to generate the configuration from
      def add_index(index)
        source = Riddle::Configuration::XMLSource.new(index.name, :xmlpipe2)
        riddle_index = Riddle::Configuration::Index.new(index.name, source)
        apply_global_settings(Riddle::Configuration::Index, @index, riddle_index)
        apply_global_settings(Riddle::Configuration::XMLSource, @source, source)
        index.settings.each do |setting, value|
          method = "#{setting}="
          if riddle_index.respond_to?(method)
            riddle_index.send(method, value)
          elsif source.respond_to?(method)
            source.send(method, value)
          end
        end
        riddle_index.path = File.join(riddle_index.path, index.name.to_s)
        @indices << riddle_index
      end

      # Applies the settings definedon the configuration file to the current Index or Source.
      # Used internally by {#add_index} so you should never need to call it directly
      #
      # @param section [Class] either Riddle::Configuration::Index or Riddle::Configuration::XMLSource
      # @param global [Riddle::Configuration::Index, Riddle::Configuration::XMLSource] the object that holds the global settings values
      # @param instance [Riddle::Configuration::Index, Riddle::Configuration::XMLSource] the object that settings are being set
      def apply_global_settings(section, global, instance)
        section.settings.each do |setting|
          value = global.send("#{setting}")
          instance.send("#{setting}=", value)
        end
      end

      # Renders the configuration to the output_path
      def render
        File.open(@file.output_path, "w") { |file| file.write(super) }
      end
    end
  end
end
