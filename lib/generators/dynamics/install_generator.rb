require 'rails/generators/base'

module Dynamics
  module Generators

    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      def create_initializer_file
        copy_file "dynamics.rb", "config/initializers/dynamics.rb"
      end
    end

  end
end
