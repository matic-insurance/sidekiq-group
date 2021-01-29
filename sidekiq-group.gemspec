lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/group/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-group'
  spec.version       = Sidekiq::Group::VERSION
  spec.authors       = ['Matic developers']
  spec.email         = %w[yuriy.l@matic.com oleh.m@matic.com viktoriia.b@matic.com]

  spec.summary       = 'An addon for Sidekiq that provides master-slave functionality'
  spec.description   = 'An addon for Sidekiq that provides master-slave functionality'
  spec.homepage      = 'https://github.com/matic-insurance/sidekiq-group'
  spec.license       = 'MIT'

  # # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #
  #   spec.metadata["homepage_uri"] = spec.homepage
  #   spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #   spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files = Dir['lib/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4.0'
  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'sidekiq', '>= 5.1', '< 6'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
end
