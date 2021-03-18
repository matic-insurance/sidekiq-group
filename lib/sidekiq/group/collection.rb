require 'securerandom'
require 'sidekiq/group/worker'

module Sidekiq
  module Group
    class Collection
      CID_EXPIRE_TTL = 3600 * 24 * 30
      LOCK_TTL = 3600

      attr_reader :cid, :callback_class, :callback_options

      def initialize(cid = nil)
        @cid = cid || SecureRandom.urlsafe_base64(16)
      end

      def callback_class=(value)
        @callback_class = value
        persist('callback_class', value)
      end

      def callback_options=(value)
        @callback_options = value
        persist('callback_options', value.to_json)
      end

      def add(jid)
        Sidekiq.redis do |r|
          r.multi do
            r.sadd("#{@cid}-jids", jid)
            r.expire("#{@cid}-jids", CID_EXPIRE_TTL)
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
        Sidekiq::Group::Worker.perform_async(callback_class, options)

        cleanup_redis
      end

      private

      def remove_processed(jid)
        Sidekiq.redis { |r| r.srem("#{@cid}-jids", jid) }
      end

      def pending
        Sidekiq.redis { |r| r.scard("#{@cid}-jids") }
      end

      def processed_all_jobs?
        spawned_all_jobs? && pending.zero?
      end

      def spawned_all_jobs?
        Sidekiq.redis { |r| r.hget(@cid, 'spawned_jobs') }.present?
      end

      def callback_data
        Sidekiq.redis do |r|
          r.multi do
            r.hget(@cid, 'callback_class')
            r.hget(@cid, 'callback_options')
          end
        end
      end

      def persist(attribute, value)
        Sidekiq.redis do |r|
          r.multi do
            r.hset(@cid, attribute, value)
            r.expire(@cid, CID_EXPIRE_TTL)
          end
        end
      end

      def cleanup_redis
        Sidekiq.redis { |r| r.del(@cid, "#{@cid}-jids") }
      end

      def locked?
        Sidekiq.redis do |r|
          r.multi do
            r.getset("#{@cid}-finished", 1)
            r.expire("#{@cid}-finished", LOCK_TTL)
          end.first
        end
      end
    end
  end
end
