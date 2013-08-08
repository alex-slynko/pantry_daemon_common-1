require 'json'
require 'aws-sdk'

module Wonga
  module Daemon
    class Publisher
      def initialize(topic, logger)
        sns = AWS::SNS.new
        @topic = sns.topics[topic]
        @logger = logger
      end

      def publish(message)
        @logger.info "Publishing message to #{@topic}"
        @logger.debug message.to_s
        @topic.publish message.to_json
      end
    end
  end
end
