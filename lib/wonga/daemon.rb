require 'daemons'
require 'logger'
require 'syslogger'
require 'wonga/daemon/aws_resource'
require 'wonga/daemon/config'
require 'wonga/daemon/pantry_api_client'
require 'wonga/daemon/publisher'
require 'wonga/daemon/subscriber'

module Wonga
  module Daemon
    class << self
      attr_reader :config

      def load_config(filename)
        @config = Wonga::Daemon::Config.load(filename)
      end

      def publisher
        @publisher ||= Wonga::Daemon::Publisher.new(config['sns']['topic_arn'], logger)
      end

      def error_publisher
        @error_publisher ||= Wonga::Daemon::Publisher.new(config['sns']['error_arn'], logger)
      end

      def run_with_scheduler(handler)
        scheduler.interval(config['scheduler']['interval'], first: :immediately, overlap: false, timeout: config['scheduler']['timeout']) do
          time_start = Time.now.utc
          logger.warn "Starting job at #{time_start}"
          handler.run
          time_finish = Time.now.utc
          logger.warn "Completed job at #{time_finish} in #{time_finish - time_start} secs"
        end
        scheduler.join
      rescue => e
        logger.error e.inspect
        retry
      end

      def run(handler)
        Daemons.run_proc(config['daemon']['app_name'], config.daemon_config) do
          if config['sqs']
            run_without_daemon(handler)
          elsif config['scheduler']
            run_with_scheduler(handler)
          end
        end
      end

      def run_without_daemon(handler)
        Wonga::Daemon::Subscriber.new(logger, error_publisher).subscribe(config['sqs']['queue_name'], handler)
      rescue => e
        logger.error e.inspect
        retry
      end

      def logger
        @logger ||= initialize_logger
      end

      def pantry_api_client
        Wonga::Daemon::PantryApiClient.new(config['pantry']['url'], config['pantry']['api_key'], Wonga::Daemon.logger, config['pantry']['timeout'])
      end

      def aws_resource
        Wonga::Daemon::AWSResource.new(error_publisher, logger)
      end

      private

      def scheduler
        require 'rufus-scheduler'
        @scheduler ||= Rufus::Scheduler.new(frequency: config['scheduler']['frequency'])
      end

      def initialize_logger
        logger = get_logger(config['daemon']['log']) if config['daemon']['log']
        logger || Logger.new(STDOUT)
      end

      def get_logger(config_file)
        if config_file['logger'] == 'file'
          logger = Logger.new(config_file['log_file'], config_file['shift_age'])
        elsif config_file['logger'] == 'syslog'
          facility = Syslog.const_get("LOG_#{config_file['log_facility'].upcase}")
          logger = Syslogger.new(config['daemon']['app_name'], Syslog::LOG_PID | Syslog::LOG_CONS, facility)
        end

        # available levels: DEBUG(0), INFO(1), WARN(2), ERROR(3), FATAL(4), UNKNOWN(5)
        logger.level = Logger.const_get(config_file['level']) if config_file['level'] && logger
        logger
      end
    end
  end
end

at_exit do
  if Wonga::Daemon.config
    Wonga::Daemon.logger.info "Stopped at #{Time.now}"
    if $ERROR_INFO && !($ERROR_INFO.is_a?(SystemExit) && $ERROR_INFO.success?)
      Wonga::Daemon.logger.error $ERROR_INFO
      Wonga::Daemon.logger.error $ERROR_INFO.backtrace.join("\n") if $ERROR_INFO.respond_to? :backtrace
    end
  end
end
