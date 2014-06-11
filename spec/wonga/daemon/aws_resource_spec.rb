require 'spec_helper'
require 'wonga/daemon/aws_resource'

describe Wonga::Daemon::AWSResource do
  context '#find_server_by_id' do
    it 'finds server' do
      server = double
      allow(AWS::EC2).to receive_message_chain(:new, :instances).and_return('1' => server)
      expect(subject.find_server_by_id('1')).to eq server
    end
  end

  context '#stop' do
    let(:instance)  { instance_double(AWS::EC2::Instance, :exists? => true, status: status) }
    let(:instance_id) { 'i-3245243' }
    let(:ec2)       { instance_double(AWS::EC2, instances: { instance_id => instance }) }

    before(:each) do
      allow(AWS::EC2).to receive(:new).and_return(ec2)
      allow(subject).to receive(:logger).and_return(instance_double(Logger).as_null_object)
    end

    context 'machine not found' do
      let(:instance)  { instance_double(AWS::EC2::Instance, :exists? => false) }
      it 'should return nil' do
        expect(subject.stop('instance_id' => instance_id)).to be_nil
      end
    end

    context 'machine stopped' do
      let(:status) { :stopped }
      it 'should return true' do
        expect(subject.stop('instance_id' => instance_id)).to be true
      end
    end

    context 'machine terminated' do
      let(:status) { :terminated }
      it 'should return nil' do
        expect(subject.stop('instance_id' => instance_id)).to be_nil
      end
    end

    context 'machine running' do
      let(:instance)  { instance_double(AWS::EC2::Instance, :exists? => true, status: :running, stop: true) }
      it 'returns false' do
        expect { subject.stop('instance_id' => instance_id) }.to raise_error
      end
    end
  end
end
