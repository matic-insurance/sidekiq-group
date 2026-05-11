source 'https://rubygems.org'

gemspec

group :test, :development do
  gem 'bundler', '>= 1.17'
  gem 'parallel', '< 2.0' # 2.1.0 requires Ruby >= 3.3; pin to keep 3.2 in CI matrix
  gem 'rake', '~> 13.0'
  gem 'redis', '~> 5.0'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
end
