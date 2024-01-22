# frozen_string_literal: true

require 'net/ssh'
require 'socket'

# encapsulates a currently running network operation
class NetworkOperation
  attr_reader :request

  def initialize(_request); end

  def to_s
    raise 'called to_s on base class, this is invalid'
  end

  def close
    raise 'called close on base class, this is invalid'
  end
end

# encapsulates a local port_forward
class LocalPortForward < NetworkOperation
  def initialize(request)
    super
    @request = request
    @thread = Thread.new(request) do |req|
      stop = false
      Net::SSH.start(req[:host], nil, keys_only: true) do |ssh|
        ssh.forward.local(req[:bind_addr], req[:bind_port], req[:remote_addr], req[:remote_port])
        ssh.loop(0.1) { true unless stop }
        ssh.forward.cancel_local(req[:bind_port], req[:bind_addr])
      end
    end
  end

  def to_s
    @request.values.join('|')
  end

  def close
    @thread.thread_variable_set('stop', true)
  end
end

# encapsulates a remote port_forward
class RemotePortForward < NetworkOperation
  def initialize(request)
    super
    @request = request
    @thread = Thread.new(request) do |req|
      stop = false
      Net::SSH.start(req[:host], nil, keys_only: true) do |ssh|
        ssh.forward.remote(req[:bind_port], req[:bind_addr], req[:local_port], req[:local_addr])
        ssh.loop(0.1) { true unless stop }
        ssh.forward.cancel_remote(req[:bind_port], req[:bind_addr])
      end
    end
  end

  def to_s
    @request.values.join('|')
  end

  def close
    @thread.thread_variable_set('stop', true)
  end
end

def test_forward
  data = 'HELLO'
  # create the server
  TCPServer.open('127.0.0.1', 2224) do |svr|
    # create the client
    TCPSocket.open('127.0.0.1', 2222) do |c|
      # accept the connection
      s = svr.accept
      # send a hello
      c.puts data
      # validate the data sent through
      raise 'Forward test failed!!!' unless s.readline(chomp: true) == data
    end
  end
  sleep(1) # let the threads complete
end

def test_setup_port_forwards
  lpfwd = LocalPortForward.new({  'request': 'lpfwd', 'host': 'localhost', 'bind_port': 2222, 'bind_addr': 'localhost',
                                  'remote_port': 2223, 'remote_addr': 'localhost' })
  rpfwd = RemotePortForward.new({ 'request': 'rpfwd', 'host': 'localhost', 'bind_port': 2224, 'bind_addr': 'localhost',
                                  'local_port': 2223, 'local_addr': 'localhost' })
  sleep(1) # let the threads finish setting up
  [lpfwd, rpfwd]
end

def test
  puts 'testing forwards'
  # setup the ssh-agent connector
  Net::SSH::Authentication::Agent.connect(nil, nil, '/home/shellspawn/.1password/agent.sock')
  # create the port forwards
  lpfwd, rpfwd = test_setup_port_forwards
  puts lpfwd, rpfwd
  # send some data through the tunnel
  test_forward
  # close both forwards
  [lpfwd, rpfwd].map(&:close)
  puts 'all cleaned up'
end

# if ran independently, run tests
test if __FILE__ == $PROGRAM_NAME
