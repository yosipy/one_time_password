require "rails/generators"
require "rails/generators/active_record"

module OneTimePassword
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    class_option :warning_over_write, type: :boolean, default: false,
      desc: "Orver write generator files."

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    source_root File.expand_path('templates', __dir__)

    def create_initializer_file
      template = 'one_time_password'
      file_path =  "config/initializers/#{template}.rb"

      if !File.exist?(file_path) || options[:warning_over_write]
        template(file_path, File.expand_path(file_path))
      else
        ::Kernel.warn "Initializers already exists: #{template}"
      end
    end

    def create_migration_file
      template = 'create_one_time_authentication'
      file_dir = 'db/migrate'

      if !self.class.migration_exists?(File.expand_path(file_dir), template) || options[:warning_over_write]
        migration_template(
            "#{file_dir}/#{template}.rb.erb",
            "#{File.expand_path(file_dir)}/#{template}.rb",
            migration_version: migration_version
        )
      else
        ::Kernel.warn "Migration already exists: #{template}"
      end
    end

    def create_model_file
      template = 'one_time_authentication'
      file_path =  "app/models/#{template}.rb"
      if !File.exist?(file_path) || options[:warning_over_write]
        template(file_path, File.expand_path(file_path))
      else
        ::Kernel.warn "Model already exists: #{template}"
      end
    end

    private

    def migration_version
      format("[%d.%d]", ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR)
    end
  end
end
