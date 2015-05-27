require 'wonga/daemon'
require 'wonga/daemon/aws_resource'
require 'wonga/daemon/config'
require 'wonga/daemon/publisher'
require 'wonga/daemon/subscriber'
require 'rufus-scheduler'
require 'daemons'
require 'syslog/logger'
require 'logger'

RSpec.describe Wonga::Daemon do
  before(:each) do
    allow(Wonga::Daemon).to receive(:config).and_return(config)
    allow(Syslog).to receive(:open)
  end

  let(:publisher) { double }
  let(:logger) { double }
  let(:config) { {} }

  context '.aws_resource' do
    let(:aws_resource) { double }

    it 'creates aws resource' do
      allow(Wonga::Daemon).to receive(:logger).and_return(logger)
      allow(Wonga::Daemon).to receive(:error_publisher).and_return(publisher)
      expect(Wonga::Daemon::AWSResource).to receive(:new).with(publisher, logger).and_return(aws_resource)
      expect(Wonga::Daemon.aws_resource).to eq(aws_resource)
    end
  end

  context '.publisher' do
    let(:publish_arn) { 'publish' }
    let(:config) { { 'sns' => { 'topic_arn' => publish_arn } } }

    it 'creates publisher using config' do
      allow(Wonga::Daemon).to receive(:logger).and_return(logger)
      expect(Wonga::Daemon::Publisher).to receive(:new).with(publish_arn, logger).and_return(publisher)
      expect(Wonga::Daemon.publisher).to eql(publisher)
    end
  end

  context '.error_publisher' do
    let(:publish_arn) { 'publish' }
    let(:config) { { 'sns' => { 'error_arn' => publish_arn } } }

    it 'creates publisher using config' do
      allow(Wonga::Daemon).to receive(:logger).and_return(logger)
      expect(Wonga::Daemon::Publisher).to receive(:new).with(publish_arn, logger).and_return(publisher)
      expect(Wonga::Daemon.error_publisher).to eql(publisher)
    end
  end

  context '.logger' do
    let(:config) { { 'daemon' => { 'log' => logger_config, 'app_name' => app_name } } }
    let(:app_name) { 'test' }

    before(:each) do
      Wonga::Daemon.instance_variable_set(:@logger, nil)
    end

    context 'when logger type in config is file' do
      let(:file_name) { 'log.log' }
      let(:shift_age) { 'daily' }

      context 'and logger level is defined' do
        let(:logger_config) do
          {
            'logger' => 'file',
            'log_file' => file_name,
            'shift_age' => shift_age,
            'level' => 'FATAL'
          }
        end

        it 'creates regular logger with custom logger level' do
          expect(Logger).to receive(:new).with(file_name, shift_age).and_return(logger)
          expect(logger).to receive(:level=).with(4)
          expect(Wonga::Daemon.logger).to eql(logger)
        end
      end

      context 'and logger level is default' do
        let(:logger_config) do
          {
            'logger' => 'file',
            'log_file' => file_name,
            'shift_age' => shift_age
          }
        end

        it 'creates regular logger with custom logger level' do
          expect(Logger).to receive(:new).with(file_name, shift_age).and_return(logger)
          expect(Wonga::Daemon.logger).to eql(logger)
        end
      end
    end

    context 'when logger type in config is syslog' do
      context 'and logger level defined' do
        let(:logger_config) do
          {
            'logger' => 'syslog',
            'log_facility' => 'daemon',
            'level' => 'WARN'
          }
        end

        it 'creates syslogger with custom logger level' do
          expect(Syslog::Logger).to receive(:new).with(app_name, Syslog::LOG_DAEMON).and_return(logger)
          expect(logger).to receive(:level=).with(2)
          expect(Wonga::Daemon.logger).to eql(logger)
        end
      end

      context 'and logger level is default' do
        let(:logger_config) do
          {
            'logger' => 'syslog',
            'log_facility' => 'daemon'
          }
        end

        it 'creates syslogger with custom logger level' do
          expect(Syslog::Logger).to receive(:new).with(app_name, Syslog::LOG_DAEMON).and_return(logger)
          expect(Wonga::Daemon.logger).to eql(logger)
        end
      end
    end
  end

  context '.run' do
    let(:handler) { double.as_null_object }

    before(:each) do
      allow(Daemons).to receive(:run_proc)
    end

    context 'when config has sqs in config' do
      let(:config) do
        config = Wonga::Daemon::Config.new('daemon' => { 'app_name' => 'test' }, 'sqs' => {}, 'aws' => {})
        allow(config).to receive(:daemon_config).and_return({})
        config
      end

      it 'starts daemon' do
        Wonga::Daemon.run(handler)
        expect(Daemons).to have_received(:run_proc)
      end

      it 'runs using run_without_daemon internally' do
        allow(Daemons).to receive(:run_proc).and_yield
        expect(Wonga::Daemon).to receive(:run_without_daemon)
        Wonga::Daemon.run(handler)
      end
    end

    context 'when config has scheduler part in it' do
      let(:config) do
        config = Wonga::Daemon::Config.new('daemon' => { 'app_name' => 'test' }, 'scheduler' => {}, 'aws' => {})
        allow(config).to receive(:daemon_config).and_return({})
        config
      end

      it 'starts daemon' do
        Wonga::Daemon.run(handler)
        expect(Daemons).to have_received(:run_proc)
      end

      it 'runs using run_with_scheduler internally' do
        allow(Daemons).to receive(:run_proc).and_yield
        expect(Wonga::Daemon).to receive(:run_with_scheduler)
        Wonga::Daemon.run(handler)
      end
    end
  end

  context '.run_without_daemon' do
    let(:subscriber) { instance_double(Wonga::Daemon::Subscriber).as_null_object }
    let(:handler) { double(handle_message: true) }
    let(:queue) { 'test_queue' }
    let(:config) { { 'sqs' => { 'queue_name' => queue }, 'daemon' => {} } }

    before(:each) do
      allow(Wonga::Daemon).to receive(:logger).and_return(logger)
      allow(Wonga::Daemon).to receive(:error_publisher).and_return(publisher)
      allow(Wonga::Daemon::Subscriber).to receive(:new).and_return(subscriber)
    end

    it 'subscribes handler to config queue' do
      expect(subscriber).to receive(:subscribe).with(queue, handler)
      Wonga::Daemon.run_without_daemon(handler)
    end
  end

  describe '.run_with_scheduler' do
    let(:scheduler) { instance_double(Rufus::Scheduler).as_null_object }
    let(:daemon_config) { {} }
    let(:handler) { double(run: true) }
    let(:config) { { 'scheduler' => { 'interval' => 0, 'timeout' => 0 } } }

    before(:each) do
      allow(logger).to receive(:warn)
      allow(logger).to receive(:info)
      allow(Wonga::Daemon).to receive(:logger).and_return(logger)
      allow(Rufus::Scheduler).to receive(:new).and_return(scheduler)
      Wonga::Daemon.instance_variable_set(:@scheduler, nil)
    end

    it 'schedules handler to run at intervals' do
      Wonga::Daemon.run_with_scheduler(handler)
      expect(scheduler).to have_received(:interval).with(
        config['scheduler']['interval'],
        first: :immediately,
        overlap: false,
        timeout: config['scheduler']['timeout']
      )
    end

    it 'scheduler joins thread' do
      Wonga::Daemon.run_with_scheduler(handler)
      expect(scheduler).to have_received(:join)
    end
  end
end
