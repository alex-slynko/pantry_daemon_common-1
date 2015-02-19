require 'aws-sdk'

module Wonga
  module Daemon
    class AWSResource
      def initialize(error_publisher, logger, ec2_resource = Aws::EC2::Resource.new)
        @ec2_resource = ec2_resource
        @error_publisher = error_publisher
        @logger = logger
      end

      def find_server_by_id(id)
        instance = @ec2_resource.instance id
        instance.load
        instance
      rescue Aws::EC2::Errors::InvalidInstanceIDNotFound
        nil
      end

      def stop(message)
        instance = find_server_by_id(message['instance_id'])

        unless instance
          @logger.error("ERROR: machine not found #{message['name']} - request_id: #{message['id']}")
          @error_publisher.publish message
          return
        end

        case instance.state.name
        when 'stopped'
          @logger.info("Stopped instance: #{message['name']} - request_id: #{message['id']} - stopped")
          return true
        when 'terminated'
          @logger.error("Attempted to stop terminated instance: #{message['name']} - id #{message['id']}")
          @error_publisher.publish message
          return
        when 'running'
          @logger.info("Stopping instance: #{message['name']} - request_id: #{message['id']} - stopping")
          instance.stop
        end

        fail "Instance #{message['instance_id']} is stopping"
      end
    end
  end
end
