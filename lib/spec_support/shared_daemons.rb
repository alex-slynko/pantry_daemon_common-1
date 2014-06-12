shared_examples 'send message' do
  it 'publishes success message' do
    publisher.stub(:publish) do |hash|
      expect(message.all? { |key, value| hash[key] == value }).to be true
    end

    subject.handle_message message
    expect(publisher).to have_received(:publish)
  end
end

shared_examples 'handler' do
  it 'can handle message' do
    expect(subject).to respond_to(:handle_message).with(1).argument
  end
end
