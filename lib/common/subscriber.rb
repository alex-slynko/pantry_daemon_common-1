require 'aws-sdk'
require_relative 'config'

module Daemons
  class Subscriber
    def subscribe(queue_name, processor)
      AWS::SQS.new.queues.named(queue_name).poll do |msg|
        begin
          message = JSON.parse(msg.body)
          message = JSON.parse(message["Message"]) if message["Message"]
          processor.handle_message(message)
        rescue JSON::ParserError => e
          false
        end
      end
    end
  end
end
