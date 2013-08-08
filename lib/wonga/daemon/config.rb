require 'aws-sdk'

module Wonga
  module Daemon
    class Config
      def initialize(config_file)
        read_config(config_file)
        configure_aws
      end

      def [](value)
        @config[value]
      end

      def daemon_config
        {
          backtrace: @config['daemon']['backtrace'],
          dir_mode: @config['daemon']['dir_mode'].to_sym,
          dir: "#{File.expand_path(@config['daemon']['dir'])}",
          monitor: @config['daemon']['monitor']
        }
      end

      private
      def read_config(config_file)
        env = ENV['ENVIRONMENT'] || 'development'
        @config = YAML.load_file(config_file)[env]
      end

      def configure_aws
        AWS.config(@config["aws"])
      end
    end
  end
end
