require 'spec_helper'
require 'wonga/daemon'

describe Wonga::Daemon do
  before(:each) do
    allow(Wonga::Daemon).to receive(:config).and_return(config)
  end

  context '.publisher' do
    let(:publish_arn) { 'publish' }
    let(:publisher) { double }
    let(:logger) { double }
    let(:config) { { 'sns' => { 'topic_arn' => publish_arn } } }

    it 'creates publisher using config' do
      allow(Wonga::Daemon).to receive(:logger).and_return(logger)
      expect(Wonga::Daemon::Publisher).to receive(:new).with(publish_arn, logger).and_return(publisher)
      expect(Wonga::Daemon.publisher).to eql(publisher)
    end
  end

  context '.logger' do
    let(:config) { { 'daemon' => { 'log' => logger_config, 'app_name' => app_name } } }
    let(:app_name) { 'test' }
    let(:logger) { double }

    before(:each) do
      Wonga::Daemon.instance_variable_set(:@logger, nil)
    end

    context 'when logger type in config is file' do
      let(:file_name) { 'log.log' }
      let(:shift_age) { 'daily' }
      let(:logger_config) do
        {
          'logger' => 'file',
          'log_file' => file_name,
          'shift_age' => shift_age
        }
      end

      it 'creates regular logger' do
        expect(Logger).to receive(:new).with(file_name, shift_age).and_return(logger)
        expect(Wonga::Daemon.logger).to eql(logger)
      end
    end

    context 'when logger type in config is syslog' do
      let(:logger_config) do
        {
          'logger' => 'syslog',
          'log_facility' => 'daemon'
        }
      end

      it 'creates syslogger' do
        expect(Syslogger).to receive(:new).with(app_name, Syslog::LOG_PID | Syslog::LOG_CONS, Syslog::LOG_DAEMON).and_return(logger)
        expect(Wonga::Daemon.logger).to eql(logger)
      end
    end
  end

  context '.run' do
    let(:config) do
      config = Wonga::Daemon::Config.new('daemon' => { 'app_name' => 'test' }, 'aws' => {})
      allow(config).to receive(:daemon_config).and_return({})
      config
    end

    let(:handler) { double.as_null_object }

    before(:each) do
      allow(Daemons).to receive(:run_proc)
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

  context '.run_without_daemon' do
    let(:subscriber) { instance_double('Wonga::Daemon::Subscriber').as_null_object }
    let(:handler) { double.as_null_object }
    let(:queue) { 'test_queue' }
    let(:config) { { 'sqs' => { 'queue_name' => queue }, 'daemon' => {} } }

    before(:each) do
      allow(Wonga::Daemon::Subscriber).to receive(:new).and_return(subscriber)
    end

    it 'subscribes handler to config queue' do
      expect(subscriber).to receive(:subscribe).with(queue, handler)
      Wonga::Daemon.run_without_daemon(handler)
    end
  end
end
