require 'spec_helper'
require 'wonga/daemon/config'
require 'fakefs/safe'

RSpec.describe Wonga::Daemon::Config do
  subject { described_class.new config }
  let(:aws_config) { {} }
  let(:config) { { 'daemon' => daemons_config, 'aws' => aws_config } }
  let(:daemons_config) { { 'daemons_count' => daemons_count, 'dir' => file, 'dir_mode' => 'dir' } }
  let(:daemons_count) { 1 }
  let(:file) { 'here' }

  context '.load' do
    let(:aws_config) { { 'region' => 'eu-west-1', 'secret_access_key' => 'KEY', 'access_key_id' => 'KEY_ID' } }

    before(:all) do
      FakeFS.activate!
    end

    after(:all) do
      FakeFS.deactivate!
    end

    before(:each) do
      File.open(file, 'w') do |file_content|
        file_content.puts YAML.dump(environment => config)
      end
      stub_const('ENV',  'ENVIRONMENT' => environment)
      Aws.config = {}
    end

    subject { described_class.load(file) }
    let(:environment) { 'development' }

    it 'configures AWS' do
      expect(Aws.config[:region]).to be_nil
      expect(Aws.config[:credentials]).to be_nil
      subject
      expect(Aws.config[:region]).to eq 'eu-west-1'
      expect(Aws.config[:credentials].secret_access_key).to eq 'KEY'
      expect(Aws.config[:credentials].access_key_id).to eq 'KEY_ID'
    end

    it 'uses part of config for current environment' do
      expect(subject['daemon']).to eq(daemons_config)
    end
  end

  context '#daemons_config' do
    it 'sets dir_mode value from config' do
      expect(subject.daemon_config[:dir_mode]).to eq(:dir)
    end

    context 'if daemons_count is not in config' do
      let(:daemon_config) { { 'dir' => file, 'dir_mode' => 'dir' } }

      it 'sets multiple to false' do
        expect(subject.daemon_config[:multiple]).to be_falsey
      end
    end

    context 'if daemons_count equals 1' do
      let(:daemons_count) { 1 }

      it 'sets multiple to false' do
        expect(subject.daemon_config[:multiple]).to be_falsey
      end
    end

    context 'if daemons_count is 2' do
      let(:daemons_count) { 2 }

      it 'sets multiple to true' do
        expect(subject.daemon_config[:multiple]).to be_truthy
      end
    end
  end
end
