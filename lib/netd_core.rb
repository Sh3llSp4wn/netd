# frozen_string_literal: true

require 'netd_core/request'
require 'netd_core/netop'

# the server class of cnetd
class CNetD
  # the server class of cnetd
  def initialize(socket_path)
    @path = socket_path
    @net_ops = []
  end

  def current_net_ops
    @net_ops.map(&:request).map { |v| v.values.join('|') }
  end

  def dispatch_command(request_args, soc)
    case request_args[:request]
    when OperationRequest::LOCAL_PORT_FORWARD
      @net_ops << LocalPortForward.new(request_args)
    when OperationRequest::REMOTE_PORT_FORWARD
      @net_ops << RemotePortForward.new(request_args)
    when OperationRequest::LIST_FORWARDS
      soc.puts(current_net_ops.join("\n"))
    else
      raise 'how did you get here?'
    end
  end

  def server_main
    UNIXServer.open(@path) do |serv|
      loop do
        soc = serv.accept
        line = soc.readline
        request_args = OperationRequest.new(line).parse
        dispatch_command(request_args, soc)
      end
    end
  end
end
