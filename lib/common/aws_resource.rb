require 'aws-sdk'

class AWSResource
  def find_server_by_id(id)
    aws.instances[id]
  end

  private
  def aws
    @aws ||= AWS::EC2.new
  end
end
