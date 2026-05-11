require 'sidekiq'
require 'sidekiq/group'
require 'active_support/all'
require 'redis'

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/15')
Sidekiq.configure_client { |c| c.redis = { url: redis_url } }

REDIS = Redis.new(url: redis_url)

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before { REDIS.flushdb }
end
