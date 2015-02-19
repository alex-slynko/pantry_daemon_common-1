require 'wonga/daemon/aws_resource'
require 'wonga/daemon/publisher'
require 'logger'

RSpec.describe Wonga::Daemon::AWSResource do
  subject { described_class.new(error_publisher, logger, Aws::EC2::Resource.new(client: ec2_client)) }
  let(:ec2_client) { Aws::EC2::Client.new(stub_responses: true) }
  let(:logger) { instance_double(Logger).as_null_object }
  let(:error_publisher) { instance_double(Wonga::Daemon::Publisher).as_null_object }
  let(:response) { { reservations: [{ instances: [instance_attributes] }] } }
  before(:each) do
    ec2_client.stub_responses(:describe_instances, response)
  end

  context '#find_server_by_id' do
    let(:instance_attributes) { { instance_id: '100100' } }
    context 'when server does not exist' do
      let(:response) { 'InvalidInstanceIDNotFound' }

      it 'returns nil' do
        expect(subject.find_server_by_id('1')).to be nil
      end
    end

    it 'loads all info' do
      instance = subject.find_server_by_id('1')
      expect(instance.instance_id).to eq '100100'
    end
  end

  context '#stop' do
    let(:message) { { 'instance_id' => 'test' } }
    let(:instance_attributes) { { state: { name: state } } }

    context 'machine not found' do
      let(:response) { 'InvalidInstanceIDNotFound' }

      it 'returns nil' do
        expect(subject.stop(message)).to be nil
      end

      it 'sends message to error publisher' do
        expect(error_publisher).to receive(:publish)
        subject.stop(message)
      end
    end

    context 'machine stopped' do
      let(:state) { 'stopped' }

      it 'returns true' do
        expect(subject.stop(message)).to be true
      end
    end

    context 'machine terminated' do
      let(:state) { 'terminated' }
      it 'should return nil' do
        expect(subject.stop(message)).to be nil
      end

      it 'sends message to error publisher' do
        expect(error_publisher).to receive(:publish)
        subject.stop(message)
      end
    end

    context 'machine running' do
      let(:state) { 'running' }

      it 'raises exception' do
        expect { subject.stop(message) }.to raise_error
      end

      it 'stops machine' do
        expect { subject.stop(message) }.to raise_error
      end
    end
  end
end
