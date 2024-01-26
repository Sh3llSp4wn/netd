# frozen_string_literal: true

require 'netd_core/request'
require 'netd_core/netop'

# the server class of netd
class NetD
  # the server class of netd
  def initialize(socket_path, logger)
    @path = socket_path
    @net_ops = []
    @logger = logger
  end

  # standard connection to the netd.socket unix server
  def self.connect_to_netd(&block)
    # open the socket and execute the block
    UNIXSocket.open("#{Dir.home}/.local/run/netd.socket", &block)
  # if failed, print error
  rescue Errno::ECONNREFUSED => e
    puts "NetD server does not appear to be running #{e}"
  end

  def self.get_direction(command)
    command == OperationRequest::LOCAL_PORT_FORWARD ? 'remote' : 'local'
  end

  def self.parse_line(line)
    tokens = line.split('|')
    req = { 'request': tokens[0], 'host': tokens[1], 'bind_addr': tokens[2], 'bind_port': tokens[3] }
    return if tokens[0] == 'OKAY'

    direction = NetD.get_direction(tokens[0])
    req["#{direction}_addr"] = tokens[4]
    req["#{direction}_port"] = tokens[5]
    req
  end

  def self.parse_list(sock)
    line = sock.readline.chomp
    number_of_lines = line[0..-2].to_i
    number_of_lines.times do
    ap NetD.parse_line sock.readline.chomp
    end
  end

  def current_net_ops
    @net_ops.map(&:request).map { |v| v.values.join('|') }
  end

  def dispatch_command(request_args, server_socket)
    case request_args[:request]
    when OperationRequest::LOCAL_PORT_FORWARD
      @net_ops << LocalPortForward.new(request_args)
    when OperationRequest::REMOTE_PORT_FORWARD
      @net_ops << RemotePortForward.new(request_args)
    when OperationRequest::LIST_FORWARDS
      server_socket.puts("#{current_net_ops.length}|\n#{current_net_ops.join("\n")}")
    else
      raise 'how did you get here?'
    end
  end

  def server_main
    UNIXServer.open(@path) do |serv|
      loop do
        server_socket = serv.accept
        dispatch_command(OperationRequest.new(server_socket.readline).parse, server_socket)
        server_socket.puts 'OKAY|'
      rescue EOFError, Errno::EPIPE, RuntimeError => e
        @logger.error("Malformed Request: #{e.message}\n#{e.backtrace} ")
      end
    end
  end
end
