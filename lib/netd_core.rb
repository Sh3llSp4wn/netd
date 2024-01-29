# frozen_string_literal: true

require 'netd_core/request'
require 'netd_core/netop'

# the server class of netd
class NetDSvr
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

  # if local then the field is 'remote' if remote the command requires 'local'
  def self.get_direction(command)
    command == NetD::OperationRequest::LOCAL_PORT_FORWARD ? 'remote' : 'local'
  end

  def self.parse_line(line)
    tokens = line.split('|')
    # common to both commands
    req = { 'request': tokens[0], 'host': tokens[1], 'bind_addr': tokens[2], 'bind_port': tokens[3] }
    # detect last line
    return if tokens[0] == 'OKAY'

    # add the fields to the output
    direction = NetDSvr.get_direction(tokens[0])
    req["#{direction}_addr"] = tokens[4]
    req["#{direction}_port"] = tokens[5]
    req
  end

  def self.parse_list(sock)
    # parse the first line (number of entries)
    entries = []
    number_of_lines = sock.readline.chomp[0..-2].to_i
    number_of_lines.times do
      # pretty print the hash result from parse_line
      entries << NetDSvr.parse_line(sock.readline.chomp)
    end
    entries
  end

  def current_net_ops
    # get a list of the commands used
    # to dispatch the network operations
    @net_ops.map(&:request).map { |v| v.values.join('|') }
  end

  def del_request(request_args)
    @net_ops.each do |n|
      case request_args[:request]
      when NetD::OperationRequest::DELETE_LOCAL_PORT_FORWARD
        if (n.request[:remote_addr] == request_args[:remote_addr]) && (n.request[:remote_port] == request_args[:remote_port])
          n.close
          @net_ops.delete(n)
          return true
        end
      when NetD::OperationRequest::DELETE_REMOTE_PORT_FORWARD
        if (n.request[:local_addr] == request_args[:local_addr]) && (n.request[:local_port] == request_args[:local_port])
          n.close
          @net_ops.delete(n)
          return true
        end
      end
    end
    false
  end

  def dispatch_command(request_args, server_socket)
    # switch on the request type, dispatch the request,
    # and add the object to the tracking list
    case request_args[:request]
    when NetD::OperationRequest::LOCAL_PORT_FORWARD
      @net_ops << NetD::LocalPortForward.new(request_args)
    when NetD::OperationRequest::REMOTE_PORT_FORWARD
      @net_ops << NetD::RemotePortForward.new(request_args)
    when NetD::OperationRequest::DELETE_LOCAL_PORT_FORWARD
      del_request(request_args)
    when NetD::OperationRequest::DELETE_REMOTE_PORT_FORWARD
      del_request(request_args)
    when NetD::OperationRequest::LIST_FORWARDS
      server_socket.puts("#{current_net_ops.length}|\n#{current_net_ops.join("\n")}")
    else
      raise 'how did you get here?'
    end
  end

  def server_main
    UNIXServer.open(@path) do |serv|
      # accept, dispatch, respond for all connections
      loop do
        # accept new connection
        server_socket = serv.accept
        # read command, parse it, and dispatch it
        dispatch_command(NetD::OperationRequest.new(server_socket.readline).parse, server_socket)
        # respond with success
        server_socket.puts 'OKAY|'
      rescue EOFError, Errno::EPIPE, RuntimeError => e
        # if connection fails or bad data is sent, report error
        @logger.error("Malformed Request: #{e.message}\n#{e.backtrace} ")
        server_socket.puts 'ERR|' unless server_socket.closed?
      end
    end
  end
end
