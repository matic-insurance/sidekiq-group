lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/group/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-group'
  spec.version       = Sidekiq::Group::VERSION
  spec.authors       = ['Matic developers']
  spec.email         = %w[yuriy.l@matic.com oleh.m@matic.com viktoriia.b@matic.com]

  spec.summary       = 'Addon for Sidekiq that provides similar functionality to Pro version Batches feature'
  spec.description   = 'Allows to group jobs into a set and follow their progress'
  spec.homepage      = 'https://github.com/matic-insurance/sidekiq-group'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files = Dir['lib/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4.0'
  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'sidekiq', '>= 5.1', '< 6'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 13.0'
end
