require 'spec_helper'
require 'common/daemon'
require 'common/publisher'

describe Daemon do
  context ".publisher" do
    let(:publish_arn) { 'publish' }
    let(:publisher) { double }
    let(:logger) { double }

    it "creates publisher using config" do
      Daemon.stub(:config).and_return({ 'sns' => { 'topic_arn' => publish_arn } })
      Daemon.stub(:logger).and_return(logger)
      expect(Publisher).to receive(:new).with(publish_arn, logger).and_return(publisher)
      expect(Daemon.publisher).to eql(publisher)
    end
  end

  context ".run" do
    let(:config) do
      config = { 'daemon' => { 'app_name' => 'test' } }
      config.stub(:daemon_config).and_return({})
      config
    end

    let(:handler) { double.as_null_object }

    before(:each) do
      Daemon.stub(:config).and_return(config)
      Daemons.stub(:run_proc)
    end

    it "starts daemon" do
      Daemon.run(handler)
      expect(Daemons).to have_received(:run_proc)
    end
  end
end
