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
        @static_indexes = {}
        @generated_indexes = {}
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

      # Adds an index to the sphinx configuration,
      # so this index can be rendered on the configuration file
      #
      # @param index [Mongoid::Giza::Index] the index that will be added to the configuration
      # @param generated [TrueClass, FalseClass] determines if this index was generated from a {Mongoid::Giza::DynamicIndex}
      def add_index(index, generated = false)
        riddle_index = create_index(index)
        if generated
          position = register_index(riddle_index, @generated_indexes)
        else
          position = register_index(riddle_index, @static_indexes)
        end
        indices[position] = riddle_index
      end

      # Creates a new Riddle::Index based on the given {Mongoid::Giza::Index}
      #
      # @param index [Mongoid::Giza::Index] the index to generate the configuration from
      #
      # @return [Riddle::Configuration::Index] the created riddle index
      def create_index(index)
        source = Riddle::Configuration::XMLSource.new(index.name, :xmlpipe2)
        riddle_index = Riddle::Configuration::Index.new(index.name, source)
        apply_default_settings(@index, riddle_index)
        apply_default_settings(@source, source)
        apply_user_settings(index, riddle_index)
        apply_user_settings(index, source)
        riddle_index.path = File.join(riddle_index.path, index.name.to_s)
        riddle_index.charset_type = "utf-8"
        riddle_index
      end

      # Adds the riddle index to it's respective collection
      #
      # @param index [Riddle::Configuration::Index] the index that will be registrated
      # @param indexes [Hash] the collection which will hold this index
      #
      # @return [Integer] the position where this index should be inserted on the configuration indices array
      def register_index(index, indexes)
        position = indexes.has_key?(index.name) ?  indices.index(indexes[index.name]) : indices.length
        indexes[index.name] = index
        position
      end

      # Applies the settings defined on an object loaded from the configuration to a Riddle::Configuration::Index or Riddle::Configuration::XMLSource instance.
      # Used internally by {#add_index} so you should never need to call it directly
      #
      # @param default [Riddle::Configuration::Index, Riddle::Configuration::XMLSource] the object that holds the global settings values
      # @param section [Riddle::Configuration::Index, Riddle::Configuration::XMLSource] the object that settings are being set
      def apply_default_settings(default, section)
        default.class.settings.each do |setting|
          method = "#{setting}="
          value = default.send("#{setting}")
          section.send(method, value) if !value.nil? and section.respond_to?(method)
        end
      end

      # Applies the settings defined on a {Mongoid::Giza::Index} to the Riddle::Configuration::Index or Riddle::Configuration::XMLSource.
      # Used internally by {#add_index} so you should never need to call it directly
      #
      # @param index [Mongoid::Giza::Index] the index where the settings were defined
      # @param section [Riddle::Configuration::Index, Riddle::Configuration::XMLSource] where the settings will be applied
      def apply_user_settings(index, section)
        index.settings.each do |setting, value|
          method = "#{setting}="
          section.send(method, value) if section.respond_to?(method)
        end
      end

      # Renders the configuration to the output_path
      def render
        File.open(@file.output_path, "w") { |file| file.write(super) }
      end
    end
  end
end
