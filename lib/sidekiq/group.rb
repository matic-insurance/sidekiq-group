require 'sidekiq/logging'
require 'sidekiq/group/version'
require 'sidekiq/group/collection'
require 'sidekiq/group/middleware'

module Sidekiq
  module Group
    class NoBlockGivenError < StandardError; end

    def sidekiq_group(options = {})
      raise NoBlockGivenError unless block_given?

      group = Sidekiq::Group::Collection.new
      group.callback_class = self.class.name
      group.callback_options = options

      Thread.current[:group_collection] = group

      yield(group)

      group.spawned_jobs!

      Thread.current[:group_collection] = nil
    end

    def on_complete(_options = {})
      sidekiq_logger.warn 'on_complete function is not defined'
    end

    def sidekiq_logger
      Sidekiq::Logging.logger
    end
  end
end
