require 'json'
require 'aws-sdk'
require 'wonga/daemon'

module Wonga
  module Daemon
    class Subscriber
      def initialize(logger, error_publisher, client = Aws::SQS::Client.new)
        @logger = logger
        @client = client
        @error_publisher = error_publisher
      end

      def subscribe(queue_name, processor)
        url = @client.get_queue_url(queue_name: queue_name).queue_url
        loop do
          message = @client.receive_message(queue_url: url).messages.first
          if message
            @logger.info "Read message from #{queue_name}"
            @client.delete_message(queue_url: url, receipt_handle: message.receipt_handle) if process(processor, message.body)
          end
          sleep 5
        end
      end

      private

      def process(processor, message)
        processor.handle_message(parse(message))
        true
      rescue ::JSON::ParserError => e
        error_message = "Bad message. Message body: #{message}. Backtrace: #{e.backtrace}."
        @error_publisher.publish(error: error_message)
        @logger.error error_message
        true
      rescue
        false
      end

      def parse(msg)
        message = JSON.parse(msg)
        message = JSON.parse(message['Message']) if message['Message']
        @logger.debug message.to_s
        message
      end
    end
  end
end
