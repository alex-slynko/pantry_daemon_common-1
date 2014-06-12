require 'aws-sdk'

module Wonga
  module Daemon
    class Subscriber
      def initialize(logger, config)
        @logger = logger
        @config = config
      end

      def subscribe(queue_name, processor)
        AWS::SQS.new.queues.named(queue_name).poll do |msg|
          begin
            @logger.info "Read message from #{queue_name}"
            message = JSON.parse(msg.body)
            message = JSON.parse(message['Message']) if message['Message']
            @logger.debug message.to_s
            processor.handle_message(message)
          rescue JSON::ParserError => e
            error_message = "Bad message. Message body: #{msg.body}. Backtrace: #{e.backtrace}."
            ::Wonga::Daemon::Publisher.new(@config['sns']['error_arn'], @logger).publish(error: error_message)
            @logger.error error_message
            false
          end
        end
      end
    end
  end
end
