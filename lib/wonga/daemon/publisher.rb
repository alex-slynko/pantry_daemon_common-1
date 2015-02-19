require 'json'
require 'aws-sdk'

module Wonga
  module Daemon
    class Publisher
      def initialize(topic_name, logger, sns_resource = Aws::SNS::Resource.new)
        @topic = sns_resource.topic topic_name
        @logger = logger
      end

      def publish(message)
        @logger.info "Publishing message to #{@topic}"
        @logger.debug message.to_s
        @topic.publish message: message.to_json
      end
    end
  end
end
