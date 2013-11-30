require "rails"

module Mongoid
  module Giza
    class Railtie < Rails::Railtie
      initializer "mongoid-giza.load-configuration" do
        file = Rails.root.join("config", "giza.yml")
        Mongoid::Giza::Configuration.instance.load(file, Rails.env) if file.file?
      end
    end
  end
end
