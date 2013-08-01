require 'aws-sdk'

class Publisher
  def initialize(topic)
    sns = AWS::SNS.new
    @topic = sns.topics[topic]
  end

  def publish(message)
    @topic.publish message.to_json
  end
end

