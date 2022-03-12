require_relative "lib/one_time_password/version"

Gem::Specification.new do |spec|
  spec.name        = "one_time_password"
  spec.version     = OneTimePassword::VERSION
  spec.authors     = ["yosipy"]
  spec.email       = ["yosi.contact@gmail.com"]
  spec.homepage    = "https://github.com/yosipy/one_time_password"
  spec.summary     = "One time password.(todo: Write a short summary, because RubyGems requires one.)"
  # spec.description = "todo: Description of OneTimePassword."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "todo: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yosipy/one_time_password"
  spec.metadata["changelog_uri"] = "https://github.com/yosipy/one_time_password/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.2.3"
  spec.add_development_dependency "rspec-rails"
end
