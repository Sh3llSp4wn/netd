# frozen_string_literal: true

Gem::Specification.new do |g|
  g.name = 'netd'
  g.version = '0.0.2'
  g.required_ruby_version = '>= 3.0.0'
  g.executables = %w[netd netc]
  g.summary = 'Server used for background port fwds'
  g.description = 'cnetd is a small userspace server that allows for cnet to request port forwards and other services'
  g.authors = ['shellspawn']
  g.email = 'shellspawn@protonmail.com'
  g.files = ['lib/netd_core.rb', 'lib/netd_core/request.rb', 'lib/netd_core/netop.rb']
  g.licenses = ''
end
