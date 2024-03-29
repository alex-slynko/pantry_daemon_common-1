require 'spec_helper'
require 'wonga/daemon/ssh_runner'

RSpec.describe Wonga::Daemon::SshRunner do
  let(:server) { double }

  before(:each) do
    allow(Net::SSH::Multi).to receive(:start).and_return(server)
  end

  context '#add_host' do
    let(:host) { 'some.host' }

    it 'adds host with default user name and key' do
      expect(server).to receive(:use).with("ubuntu@#{host}",  keys: File.expand_path('~/.ssh/aws-ssh-keypair.pem'), keys_only: true)
      subject.add_host(host)
    end

    it 'adds host with set params' do
      expect(server).to receive(:use).with('user@host',  keys: 'key', keys_only: true)
      subject.add_host('host', 'user', 'key')
    end
  end

  context '#run_commands' do
    before(:each) do
      allow(server).to receive(:loop)
      allow(server).to receive(:close)
    end

    it 'exec each command separately' do
      expect(server).to receive(:exec).twice
      subject.run_commands('test', 'test')
    end
  end
end
