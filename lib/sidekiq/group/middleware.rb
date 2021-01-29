module Sidekiq
  module Group
    module Middleware
      class ClientMiddleware
        def call(_worker, msg, _queue, _redis_pool = nil)
          if (group = Thread.current[:group_collection])
            msg['cid'] = group.cid
          end

          yield
        end
      end

      class ServerMiddleware
        def call(_worker, msg, _queue)
          yield

          return unless msg['cid']

          Sidekiq::Group::Collection.new(msg['cid']).success(msg['jid'])
        end
      end

      def self.configure
        Sidekiq.configure_client do |config|
          config.client_middleware { |c| c.add Sidekiq::Group::Middleware::ClientMiddleware }
        end
        Sidekiq.configure_server do |config|
          config.client_middleware { |c| c.add Sidekiq::Group::Middleware::ClientMiddleware }
          config.server_middleware { |c| c.add Sidekiq::Group::Middleware::ServerMiddleware }
        end
      end
    end
  end
end

Sidekiq::Group::Middleware.configure
