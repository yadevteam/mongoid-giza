require "erb"
require "ostruct"
require "yaml"

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
        @file = OpenStruct.new(output_path: "./sphinx.conf")
        @static_indexes = {}
        @generated_indexes = {}
      end

      # Loads a YAML file with settings defined.
      # Settings that are not recognized are ignored
      #
      # @param path [String] path to the YAML file which contains the settings
      #   defined
      # @param env [String] environment whoose settings will be loaded
      def load(path, env)
        YAML.load(File.open(path).read)[env].each do |section_name, settings|
          section = instance_variable_get("@#{section_name}")
          next unless section
          settings.each do |setting, value|
            unless section == @index || section == @source
              value = interpolate_string(value, nil)
            end
            setter(section, setting, value)
          end
        end
      end

      # Adds an index to the sphinx configuration,
      # so this index can be rendered on the configuration file
      #
      # @param index [Mongoid::Giza::Index] the index that will be added to the
      #   configuration
      # @param generated [TrueClass, FalseClass] determines if this index was
      #   generated from a {Mongoid::Giza::DynamicIndex}
      def add_index(index, generated = false)
        riddle_index = create_index(index)
        indexes = generated ? @generated_indexes : @static_indexes
        position = register_index(riddle_index, indexes)
        indices[position] = riddle_index
      end

      # Creates a new Riddle::Index based on the given {Mongoid::Giza::Index}
      #
      # @param index [Mongoid::Giza::Index] the index to generate the
      #   configuration from
      #
      # @return [Riddle::Configuration::Index] the created riddle index
      def create_index(index)
        source = Riddle::Configuration::XMLSource.new(index.name, :xmlpipe2)
        riddle_index = Riddle::Configuration::Index.new(index.name, source)
        apply_default_settings(@index, riddle_index, index)
        apply_default_settings(@source, source, index)
        apply_user_settings(index, riddle_index)
        apply_user_settings(index, source)
        riddle_index.path = File.join(riddle_index.path, index.name.to_s)
        riddle_index
      end

      # Adds the riddle index to it's respective collection
      #
      # @param riddle_index [Riddle::Configuration::Index] the index that will
      #   be registrated
      # @param indexes [Hash] the collection which will hold this index
      #
      # @return [Integer] the position where this index should be inserted on
      #   the configuration indices array
      def register_index(riddle_index, indexes)
        indexes[riddle_index.name] = riddle_index
        indices.index(riddle_index) || indices.length
      end

      # Applies the settings defined on an object loaded from the configuration
      #   to a Riddle::Configuration::Index or Riddle::Configuration::XMLSource
      #   instance.
      # Used internally by {#add_index} so you should never need to call it
      #   directly
      #
      # @param default [Riddle::Configuration::Index,
      #   Riddle::Configuration::XMLSource] the object that holds the global
      #   settings values
      # @param section [Riddle::Configuration::Index,
      #   Riddle::Configuration::XMLSource] the object that settings are being
      #   set
      def apply_default_settings(default, section, index)
        default.class.settings.each do |setting|
          value = interpolate_string(default.send("#{setting}"), index)
          setter(section, setting, value) unless value.nil?
        end
      end

      # Applies the settings defined on a {Mongoid::Giza::Index} to the
      #   Riddle::Configuration::Index or Riddle::Configuration::XMLSource.
      # Used internally by {#add_index} so you should never need to call it
      #   directly
      #
      # @param index [Mongoid::Giza::Index] the index where the settings were
      #   defined
      # @param section [Riddle::Configuration::Index,
      #   Riddle::Configuration::XMLSource] where the settings will be applied
      def apply_user_settings(index, section)
        index.settings.each do |setting, value|
          value = interpolate_string(value, index)
          setter(section, setting, value)
        end
      end

      # Renders the configuration to the output_path
      def render
        File.open(@file.output_path, "w") { |file| file.write(super) }
      end

      # Removes all Riddle::Index from the indices Array that were created from
      #   a generated {Mongoid::Giza::Index}
      def clear_generated_indexes
        @generated_indexes.each { |_, index| indices.delete(index) }
        @generated_indexes =  {}
      end

      # Removes Riddle::Index's specifieds as params
      #
      # @param names [Array<Symbol>] names of generated indexes that should be
      #   removed
      def remove_generated_indexes(names)
        names.each do |name|
          indices.delete(@generated_indexes.delete(name))
        end
      end

      # Interpolates a value if it's a String using ERB.
      # Useful for defining dynamic settings.
      # The ERB template may reference to the current {Mongoid::Giza::Index} and
      #   it's methods
      #
      # @param value [String] the ERB template that will be interpolated
      # @param index [Mongoid::Giza::Index] the index that will be accessible
      #   from the template
      #
      # @return [Object] if value was a String and contains ERB syntax than it
      #   will beinterpolated and returned.
      #   Otherwise it will return the original value
      def interpolate_string(value, index)
        namespace = index.nil? ? Object.new : OpenStruct.new(index: index)
        if value.is_a?(String)
          return ERB.new(value).result(namespace.instance_eval { binding })
        else
          return value
        end
      end

      # Helper method to set a value to a setting from a section (i.e. indexer,
      #   source) if the section has this setting.
      # If the setting is not avaiable on the section, nothing is done
      #
      # @param section [Riddle::Configuration::Section] a configuration section
      #   to define the setting
      # @param setting [Symbol] the setting that will be defined on the section
      # @param value [Object] the value of the setting
      def setter(section, setting, value)
        method = "#{setting}="
        section.send(method, value) if section.respond_to?(method)
      end
    end
  end
end
