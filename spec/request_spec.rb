require 'netd_core/request'

def expect_operation_request(req)
  expect(req).to be_an_instance_of(String)
  expect(req.split('|')).to be_an_instance_of(Array)
  expect(req.split('|')).not_to be_empty
end

RSpec.describe NetD::OperationRequest do
  context 'provides a line feed interface to the socket' do
    it 'generates a local forward request' do
      req = NetD::OperationRequest.local_port_forward(
        '127.0.0.1', '127.0.0.1', 1337, '127.0.0.1', 1338
      )
      expect_operation_request(req)
    end
    it 'generates a remote forward request' do
      req = NetD::OperationRequest.remote_port_forward(
        '127.0.0.1', '127.0.0.1', 1337, '127.0.0.1', 1338
      )
      expect_operation_request(req)
    end
    it 'generates a local forward delete request' do
      req = NetD::OperationRequest.delete_local_port_forward('127.0.0.1', '127.0.0.1', 1338)
      expect_operation_request(req)
    end
    it 'generates a remote forward delete request' do
      req = NetD::OperationRequest.delete_remote_port_forward('127.0.0.1', '127.0.0.1', 1338)
      expect_operation_request(req)
    end
  end
  context 'provides a sane exception interface' do
    it 'defines a malformed_request exception' do
      expect {NetD::OperationRequest.malformed_request}.to raise_error(having_attributes(message: 'malformed request'))
    end
  end
end
