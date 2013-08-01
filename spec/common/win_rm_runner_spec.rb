require 'spec_helper'
require "#{Rails.root}/daemons/common/win_rm_runner"

describe WinRMRunner do
  let(:server) { double }
  before(:each) { EventMachine::WinRM::Session.stub(:new).and_return(server) }

  context "#add_host" do
    let(:host) { "some.host" }

    it "adds host with default user name and key" do
      expect(server).to receive(:use).with(host, { user: 'Administrator', password: 'AdminPassword', basic_auth_only: true })
      subject.add_host(host)
    end

    it "adds host with set params" do
      expect(server).to receive(:use).with("host", { user: 'user', basic_auth_only: true, password: 'pass' })
      subject.add_host("host", "user", "pass")
    end
  end

  context "#run_commands" do
    it "exec each command separately" do
      expect(server).to receive(:relay_command).twice
      subject.run_commands("test", "test")
    end
  end
end
