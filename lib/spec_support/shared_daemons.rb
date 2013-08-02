shared_examples "send message" do
  it "publishes success message" do
    subject.handle_message message
    expect(publisher).to have_received(:publish).with(message)
  end
end


