require 'spec_helper'
require "wonga/daemon/config"
require 'fakefs/safe'

describe Wonga::Daemon::Config do
  before(:all) do
    FakeFS.activate!
  end

  after(:all) do
    FakeFS.deactivate!
  end

  before(:each) do
    File.open(file, 'w') do |file|
      file.puts YAML.dump(config)
    end
    stub_const('ENV', { 'ENVIRONMENT' => environment })
  end

  subject { described_class.new(file) }
  let(:file) { 'here' }
  let(:environment) { 'development' }
  let(:config) { { environment => { 'daemon' => daemons_config, 'aws' => {} }} }
  let(:daemons_config) { { 'daemons_count' => daemons_count, 'dir' => file, 'dir_mode' => 'dir' } }
  let(:daemons_count) { 1 }

  it "configures AWS" do
    expect(AWS).to receive(:config)
    subject
  end

  it "uses part of config for current environment" do
    expect(subject['daemon']).to eq(daemons_config)
  end

  context "#daemons_config" do
    it "sets dir_mode value from config" do
      expect(subject.daemon_config[:dir_mode]).to eq(:dir)
    end


    context "if daemons_count is not in config" do
      let(:daemon_config) { { 'dir' => file, 'dir_mode' => 'dir' } }

      it "sets multiple to false" do
        expect(subject.daemon_config[:multiple]).to be_false
      end
    end

    context "if daemons_count equals 1" do
      let(:daemons_count) { 1 }

      it "sets multiple to false" do
        expect(subject.daemon_config[:multiple]).to be_false
      end
    end

    context "if daemons_count is 2" do
      let(:daemons_count) { 2 }

      it "sets multiple to true" do
        expect(subject.daemon_config[:multiple]).to be_true
      end
    end
  end
end

