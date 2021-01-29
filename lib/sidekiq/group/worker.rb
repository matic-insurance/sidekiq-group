module Sidekiq
  module Group
    class Worker
      include Sidekiq::Worker

      def perform(callback_class, callback_options)
        callback = callback_class.constantize.new
        callback.on_complete(callback_options)
      end
    end
  end
end
