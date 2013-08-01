require 'net/ssh'
require 'net/ssh/multi'

class SshRunner
  def add_host(host, user="ubuntu", key=File.expand_path('~/.chef/aws-ssh-keypair.pem'))
    session.use("#{user}@#{host}", {keys: key, keys_only: true })
  end

  def run_commands(*commands, &block)
    commands.each do |command|
      session.exec command do |ch, stream, data|
        block.call(ch[:host], data) if block
      end
    end
    session.loop
    session.close
  end

  private
  def session
    @session ||= Net::SSH::Multi.start
  end
end

