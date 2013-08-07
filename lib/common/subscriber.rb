require 'aws-sdk'
require_relative 'config'

module Daemon
  class Subscriber
    def initialize(logger)
      @logger = logger
    end

    def subscribe(queue_name, processor)
      AWS::SQS.new.queues.named(queue_name).poll do |msg|
        begin
          @logger.info "Read message from #{queue_name}"
          message = JSON.parse(msg.body)
          message = JSON.parse(message["Message"]) if message["Message"]
          @logger.debug message.to_s
          processor.handle_message(message)
        rescue JSON::ParserError => e
          false
        end
      end
    end
  end
end
