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
      file_name =  "config/initializers/#{template}.rb"
      if !File.exist?(file_name) || options[:warning_over_write]
        template("#{template}.rb", file_name)
      else
        ::Kernel.warn "Model already exists: #{template}"
      end
    end

    def create_migration_file
      template = 'create_one_time_authentication'
      migration_dir = File.expand_path("db/migrate")

      if !self.class.migration_exists?(migration_dir, template) || options[:warning_over_write]
        migration_template(
            "#{template}.rb.erb",
            "#{migration_dir}/#{template}.rb",
            migration_version: migration_version
        )
      else
        ::Kernel.warn "Migration already exists: #{template}"
      end
    end

    def create_model_file
      template = 'one_time_authentication'
      file_name =  "app/models/#{template}.rb"
      if !File.exist?(file_name) || options[:warning_over_write]
        template("#{template}.rb", file_name)
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
