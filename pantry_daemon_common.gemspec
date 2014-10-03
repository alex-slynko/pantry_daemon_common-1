# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pantry_daemon_common/version'

Gem::Specification.new do |spec|
  spec.name          = 'pantry_daemon_common'
  spec.version       = PantryDaemonCommon::VERSION
  spec.authors       = ['Alex Slynko']
  spec.email         = ['pantry@wonga.com']
  spec.description   = %q(Provides the basic infrastrucutre needed for hosting and running a daemon)
  spec.summary       = %q(Daemon basic infrastructure)
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'daemons'
  spec.add_dependency 'em-winrm', '>= 0.5.5'
  spec.add_dependency 'net-ssh'
  spec.add_dependency 'net-ssh-multi'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'syslogger'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'fakefs'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov-rcov'
  spec.add_development_dependency 'webmock'

end
