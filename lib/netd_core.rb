# frozen_string_literal: true

require 'netd_core/request'
require 'netd_core/netop'

# the server class of cnetd
class CNetD
  # the server class of cnetd
  def initialize(socket_path, logger)
    @path = socket_path
    @net_ops = []
    @logger = logger
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
    soc.puts 'OKAY|'
  end

  def server_main
    UNIXServer.open(@path) do |serv|
      loop do
        soc = serv.accept
        line = soc.readline
        @logger.info(line)
        dispatch_command(OperationRequest.new(line).parse, soc)
      rescue RuntimeError => e
        @logger.error(e.backtrace)
        @logger.error(e.message)
      rescue EOFError
        @logger.error('Empty Request')
      rescue Errno::EPIPE
        @logger.error('Incomplete Request')
      end
    end
  end
end
