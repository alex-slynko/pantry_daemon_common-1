require 'daemons'
require 'common/subscriber'
require 'common/publisher'
require 'common/config'
require 'logger'
require 'syslogger'

module Daemon
  class << self
    def config
      @config
    end

    def load_config(filename)
      @config = Daemons::Config.new(filename)
    end

    def publisher
      @publisher ||= Publisher.new(config['sns']['topic_arn'], logger)
    end

    def run(handler)
      Daemons.run_proc(config['daemon']['app_name'], config.daemon_config) {
        begin
          Subscriber.new(logger).subscribe(config['sqs']['queue_name'], handler)
        rescue => e
          puts "#{e}"
          retry
        end
      }
    end

    def logger
      @logger ||= initialize_logger
    end

    private
    def initialize_logger
      log_config = config['daemon']['log']
      if log_config['logger'] == 'file'
      Logger.new(log_config['log_file'], log_config['shift_age'])
      elsif log_config['logger'] == 'syslog'
        facility = Syslog.const_get("LOG_#{log_config['log_facility'].upcase}")
        Syslogger.new(config['daemon']['app_name'], Syslog::LOG_PID | Syslog::LOG_CONS, facility)
      end
    end
  end
end

at_exit do
  if Daemon.config
    Daemon.logger.info "Stopped at #{Time.now}"
    if $! && !($!.is_a?(SystemExit) && $!.success?)
      Daemon.logger.error $!.class.to_s
      Daemon.logger.error $!.backtrace.join("\n") if $!.respond_to? :backtrace
    end
  end
end
