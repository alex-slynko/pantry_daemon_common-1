require "common/aws_resource"

describe AWSResource do
  context "#find_server_by_id" do
    it "finds server" do
      server = double
      AWS::EC2.stub_chain(:new, :instances).and_return("1" => server)
      expect(subject.find_server_by_id("1")).to eq server
    end
  end
end
