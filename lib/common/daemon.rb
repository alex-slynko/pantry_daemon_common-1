require 'daemons'
require 'common/subscriber'
require 'common/publisher'
require 'common/config'
require 'logger'

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
      @logger ||= Logger.new("log/#{config['daemon']['app_name']}.log', 'daily")
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
