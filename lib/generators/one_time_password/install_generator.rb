require "rails/generators"
require "rails/generators/active_record"

module OneTimePassword
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    source_root File.expand_path('templates', __dir__)

    def create_initializer_file
      template = 'one_time_password'
      file_name =  "config/initializers/#{template}.rb"
      if File.exist?(file_name)
        ::Kernel.warn "Model already exists: #{template}"
      else
        template("#{template}.rb", file_name)
      end
    end

    def create_migration_file
      template = 'create_one_time_authentication'
      migration_dir = File.expand_path("db/migrate")

      if self.class.migration_exists?(migration_dir, template)
        ::Kernel.warn "Migration already exists: #{template}"
      else
        migration_template(
            "#{template}.rb.erb",
            "#{migration_dir}/#{template}.rb",
            migration_version: migration_version
        )
      end
    end

    def create_model_file
      template = 'one_time_authentication'
      file_name =  "app/models/#{template}.rb"
      if File.exist?(file_name)
        ::Kernel.warn "Model already exists: #{template}"
      else
        template("#{template}.rb", file_name)
      end
    end

    private

    def migration_version
      format("[%d.%d]", ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR)
    end
  end
end
