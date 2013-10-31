require "yaml"

module Mongoid
  module Giza
    ##
    # Holds the configuration of the module
    module Config
      class << self
        attr_accessor :host, :port
        ##
        # Loads a YAML file with settings defined.
        # Settings that are not recognized are ignored
        #
        # @param path [String] path to the YAML file which contains the settings defined
        def load(path)
          YAML.load(File.open(path).read).each do |setting, value|
            method_name = "#{setting}="
            send(method_name, value) if respond_to?(method_name)
          end
        end
      end
    end
  end
end
