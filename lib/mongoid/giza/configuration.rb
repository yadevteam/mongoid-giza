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
        @index_names = []
      end

      # Loads a YAML file with settings defined.
      # Settings that are not recognized are ignored
      #
      # @param path [String] path to the YAML file which contains the settings defined
      # @param env [String] environment whoose settings will be loaded
      def load(path, env)
        YAML.load(File.open(path).read)[env].each do |section_name, settings|
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
        if !@index_names.include? index.name
          source = Riddle::Configuration::XMLSource.new(index.name, :xmlpipe2)
          riddle_index = Riddle::Configuration::Index.new(index.name, source)
          apply_settings(@index, riddle_index)
          apply_settings(@source, source)
          apply_settings(index, riddle_index)
          apply_settings(index, source)
          riddle_index.path = File.join(riddle_index.path, index.name.to_s)
          riddle_index.charset_type = "utf-8"
          @indices << riddle_index
          @index_names << index.name
        end
      end

      # Applies the settings defined on a section object to a Riddle::Configuration::Index or Riddle::Configuration::XMLSource instance.
      # Used internally by {#add_index} so you should never need to call it directly
      #
      # @param section [Riddle::Configuration::Index, Riddle::Configuration::XMLSource] the object that holds the global settings values
      # @param instance [Riddle::Configuration::Index, Riddle::Configuration::XMLSource] the object that settings are being set
      def apply_settings(section, instance)
        section.settings.each do |setting|
          method = "#{setting}="
          value = section.send("#{setting}")
          instance.send(method, value) if !value.nil? and instance.respond_to?(method)
        end
      end

      # Renders the configuration to the output_path
      def render
        File.open(@file.output_path, "w") { |file| file.write(super) }
      end
    end
  end
end
