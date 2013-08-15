require 'em-winrm'

module Wonga
  module Daemon
    class WinRMRunner
      def add_host(host, user="Administrator", password="TestPassword")
        session.use(host, {user: user, password: password, basic_auth_only: true})
      end

      def run_commands(*commands, &block)
        session.on_error do |host, data|
          block.call(host, data)
        end if block

        session.on_output do |host, data|
          block.call(host, data)
        end if block

        commands.each do |command|
          session.relay_command command
        end
      end

      private
      def session
        @session ||= EventMachine::WinRM::Session.new
      end
    end
  end
end
