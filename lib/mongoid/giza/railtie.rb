require "rails"

module Mongoid
  module Giza
    class Railtie < Rails::Railtie
      configuration = Mongoid::Giza::Configuration.instance

      initializer "mongoid-giza.load-configuration" do
        # Sets the default xmlpipe_command
        configuration.source.xmlpipe_command = "rails r '<%= index.klass %>.sphinx_indexes[:<%= index.name %>].generate_xmlpipe2(STDOUT)'"
        # Loads the configuration file
        file = Rails.root.join("config", "giza.yml")
        configuration.load(file, Rails.env) if file.file?
      end
    end
  end
end
