require 'aws-sdk'

module Wonga
  module Daemon
    class AWSResource
      def find_server_by_id(id)
        aws.instances[id]
      end

      def stop(message)
        instance = aws.instances[message['instance_id']]

        unless instance.exists?
          logger.error("ERROR: machine not found #{message["name"]} - request_id: #{message["id"]}")
          return
        end

        case instance.status
        when :stopped
          logger.info("Stopped instance: #{message["name"]} - request_id: #{message["id"]} - stopped")
          return true
        when :terminated
          logger.error("Attempted to stop terminated instance: #{message["name"]} - id #{message["id"]}")
          return
        when :running
          logger.info("Stopping instance: #{message["name"]} - request_id: #{message["id"]} - stopping")
          instance.stop
        end

        raise "Instance #{message['instance_id']} is stopping"
      end

      private
      def aws
        @aws ||= AWS::EC2.new
      end

      def logger
        Wonga::Daemon.logger
      end
    end
  end
end
