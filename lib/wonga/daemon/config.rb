require 'aws-sdk'

module Wonga
  module Daemon
    class Config
      def self.load(config_file)
        config = read_config(config_file)
        new(config)
      end

      def initialize(config)
        @config = config
        configure_aws if @config['aws']
      end

      def [](value)
        @config[value]
      end

      def daemon_config
        {
          multiple: @config['daemon']['daemons_count'].to_i > 1,
          backtrace: @config['daemon']['backtrace'],
          dir_mode: @config['daemon']['dir_mode'].to_sym,
          dir: "#{File.expand_path(@config['daemon']['dir'])}",
          monitor: @config['daemon']['monitor']
        }
      end

      private

      def self.read_config(config_file)
        require 'yaml'
        env = ENV['ENVIRONMENT'] || 'development'
        YAML.load_file(config_file)[env]
      end

      def configure_aws
        Aws.config[:region] = @config['aws']['region']
        Aws.config[:credentials] = Aws::Credentials.new(@config['aws']['access_key_id'], @config['aws']['secret_access_key'])
      end
    end
  end
end
