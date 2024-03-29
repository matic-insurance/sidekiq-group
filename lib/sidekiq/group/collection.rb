require 'securerandom'
require 'sidekiq/group/worker'

module Sidekiq
  module Group
    class Collection
      CID_EXPIRE_TTL = 3600 * 24 * 30
      LOCK_TTL = 3600

      attr_reader :cid, :callback_class, :callback_options
      alias group_id cid

      def initialize(cid = nil)
        @cid = cid || SecureRandom.urlsafe_base64(16)
        @add_method = Redis.new.respond_to?(:sadd?) ? :sadd? : :sadd
        @remove_method = @add_method == :sadd? ? :srem? : :srem
      end

      def callback_class=(value)
        @callback_class = value
        persist('callback_class', value)
      end

      def callback_options=(value)
        @callback_options = value
        persist('callback_options', value.to_json)
      end

      def initialize_total_value
        persist('total', 0)
      end

      def add(jids)
        jids = Array(jids)

        Sidekiq.logger.info "Scheduling child job #{jids} for parent #{@cid}" if Sidekiq::Group.debug

        Sidekiq.redis do |r|
          r.multi do |pipeline|
            pipeline.public_send(@add_method, "#{@cid}-jids", jids)
            pipeline.expire("#{@cid}-jids", CID_EXPIRE_TTL)
            pipeline.hincrby(@cid, 'total', jids.size)
          end
        end
      end

      def spawned_jobs!
        persist('spawned_jobs', cid)
      end

      def success(jid)
        remove_processed(jid)

        return unless processed_all_jobs?
        return if locked?

        callback_class, callback_options = callback_data
        options = JSON(callback_options)

        Sidekiq.logger.info "Scheduling callback job #{callback_class} with #{options}" if Sidekiq::Group.debug
        Sidekiq::Group::Worker.perform_async(callback_class, options)

        cleanup_redis
      end

      def total
        return unless spawned_all_jobs?

        Sidekiq.redis { |r| r.hget(@cid, 'total').to_i }
      end

      def processed
        return unless spawned_all_jobs?

        total - pending
      end

      private

      def remove_processed(jid)
        Sidekiq.logger.info "Child job #{jid} completed" if Sidekiq::Group.debug

        return if Sidekiq.redis { |r| r.public_send(@remove_method, "#{@cid}-jids", jid) }

        Sidekiq.logger.info "Could not remove child job #{jid} from Redis" if Sidekiq::Group.debug
        sleep 1
        Sidekiq.redis { |r| r.public_send(@remove_method, "#{@cid}-jids", jid) }
      end

      def pending
        @pending ||= Sidekiq.redis { |r| r.scard("#{@cid}-jids") }
      end

      def processed_all_jobs?
        Sidekiq.logger.info "Pending jobs: #{pending}" if Sidekiq::Group.debug

        spawned_all_jobs? && pending.zero?
      end

      def spawned_all_jobs?
        Sidekiq.redis { |r| r.hget(@cid, 'spawned_jobs') }.present?
      end

      def callback_data
        Sidekiq.redis do |r|
          r.multi do |pipeline|
            pipeline.hget(@cid, 'callback_class')
            pipeline.hget(@cid, 'callback_options')
          end
        end
      end

      def persist(attribute, value)
        Sidekiq.redis do |r|
          r.multi do |pipeline|
            pipeline.hset(@cid, attribute, value)
            pipeline.expire(@cid, CID_EXPIRE_TTL)
          end
        end
      end

      def cleanup_redis
        Sidekiq.redis { |r| r.del(@cid, "#{@cid}-jids") }
      end

      def locked?
        Sidekiq.redis do |r|
          r.multi do |pipeline|
            pipeline.getset("#{@cid}-finished", 1)
            pipeline.expire("#{@cid}-finished", LOCK_TTL)
          end.first
        end
      end
    end
  end
end
