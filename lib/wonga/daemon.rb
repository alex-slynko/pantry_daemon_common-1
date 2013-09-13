require 'daemons'
require 'wonga/daemon/subscriber'
require 'wonga/daemon/publisher'
require 'wonga/daemon/config'
require 'wonga/daemon/pantry_api_client'
require 'logger'
require 'syslogger'

module Wonga
  module Daemon
    class << self
      def config
        @config
      end

      def load_config(filename)
        @config = Wonga::Daemon::Config.new(filename)
      end

      def publisher
        @publisher ||= Wonga::Daemon::Publisher.new(config['sns']['topic_arn'], logger)
      end

      def run(handler)
        Daemons.run_proc(config['daemon']['app_name'], config.daemon_config) {
          run_without_daemon(handler)
        }
      end

      def run_without_daemon(handler)
        Wonga::Daemon::Subscriber.new(logger, @config).subscribe(config['sqs']['queue_name'], handler)
      rescue => e
        logger.error "#{e}"
        retry
      end

      def logger
        @logger ||= initialize_logger
      end

      def pantry_api_client
        Wonga::Daemon::PantryApiClient.new(config['pantry']['url'], config['pantry']['api_key'], Wonga::Daemon.logger, config['pantry']['timeout'])
      end

      private
      def initialize_logger
        logger = if log_config = config['daemon']['log']
          if log_config['logger'] == 'file'
            Logger.new(log_config['log_file'], log_config['shift_age'])
          elsif log_config['logger'] == 'syslog'
            facility = Syslog.const_get("LOG_#{log_config['log_facility'].upcase}")
            Syslogger.new(config['daemon']['app_name'], Syslog::LOG_PID | Syslog::LOG_CONS, facility)
          end
        end
        logger || Logger.new(STDOUT)
      end
    end
  end
end

at_exit do
  if Wonga::Daemon.config
    Wonga::Daemon.logger.info "Stopped at #{Time.now}"
    if $! && !($!.is_a?(SystemExit) && $!.success?)
      Wonga::Daemon.logger.error $!
      Wonga::Daemon.logger.error $!.backtrace.join("\n") if $!.respond_to? :backtrace
    end
  end
end
