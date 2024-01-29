# frozen_string_literal: true

# parse requests from a pipe delimited line
module NetD
  # encapsulate a request
  class OperationRequest
    LOCAL_PORT_FORWARD  = 'lpfwd'
    REMOTE_PORT_FORWARD = 'rpfwd'
    DELETE_LOCAL_PORT_FORWARD  = 'delete_lpfwd'
    DELETE_REMOTE_PORT_FORWARD = 'delete_rpfwd'
    LIST_FORWARDS = 'list'

    def initialize(request_str)
      malformed_request unless request_str.include? '|'

      blocks = request_str.split('|')
      @command = blocks[0]
      @args = blocks[1..] if blocks.length > 1
    end

    def parse
      case @command
      when LOCAL_PORT_FORWARD
        pfwd_fmt(@command, 'local')
      when REMOTE_PORT_FORWARD
        pfwd_fmt(@command, 'remote')
      when DELETE_LOCAL_PORT_FORWARD
        del_pfwd_fmt(@command, 'local')
      when DELETE_REMOTE_PORT_FORWARD
        del_pfwd_fmt(@command, 'remote')
      when LIST_FORWARDS
        { 'request': LIST_FORWARDS }
      else
        raise 'wat'
      end
    end

    def pfwd_fmt(command, direction)
      malformed_request unless @args.length == 5
      lorr = direction == 'remote' ? 'local' : 'remote'
      {
        'request': command,
        'host': @args[0],
        'bind_addr': @args[1],
        'bind_port': @args[2].to_i,
        "#{lorr}_addr": @args[3],
        "#{lorr}_port": @args[4].to_i
      }
    end

    def del_pfwd_fmt(command, direction)
      lorr = direction == 'remote' ? 'local' : 'remote'
      {
        'request': command,
        'host': @args[0],
        "#{lorr}_addr": @args[1],
        "#{lorr}_port": @args[2].to_i
      }
    end

    def self.local_port_forward(host, bind_port, bind_addr, remote_port, remote_addr)
      "#{LOCAL_PORT_FORWARD}|#{host}|#{bind_addr}|#{bind_port}|#{remote_addr}|#{remote_port}"
    end

    def self.remote_port_forward(host, bind_port, bind_addr, local_port, local_addr)
      "#{REMOTE_PORT_FORWARD}|#{host}|#{bind_addr}|#{bind_port}|#{local_addr}|#{local_port}"
    end

    def self.delete_local_port_forward(host, remote_port, remote_addr)
      "#{DELETE_LOCAL_PORT_FORWARD}|#{host}|#{remote_addr}|#{remote_port}"
    end

    def self.delete_remote_port_forward(host, local_port, local_addr)
      "#{DELETE_REMOTE_PORT_FORWARD}|#{host}|#{local_addr}|#{local_port}"
    end

    def self.malformed_request
      raise 'malformed request'
    end
  end
end
