module OneTimePassword
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path('templates', __dir__)

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

    private

    def migration_version
      format("[%d.%d]", ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR)
    end
  end
end