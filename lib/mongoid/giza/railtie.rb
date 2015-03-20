require "rails"

module Mongoid
  module Giza
    # :nodoc:
    class Railtie < Rails::Railtie
      configuration = Mongoid::Giza::Configuration.instance

      initializer "mongoid-giza.load-configuration" do
        # Sets the default xmlpipe_command
        configuration.source.xmlpipe_command =
          "rails r '<%= index.klass %>.sphinx_indexes[:<%= index.name %>]" \
          ".xmlpipe2(STDOUT)'"
        # Loads the configuration file
        giza_yml = Rails.root.join("config", "giza.yml")
        configuration.load(giza_yml, Rails.env) if giza_yml.file?
      end
    end
  end
end
