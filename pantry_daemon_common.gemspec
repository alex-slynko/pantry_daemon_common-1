# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pantry_daemon_common/version'

Gem::Specification.new do |spec|
  spec.name          = "pantry_daemon_common"
  spec.version       = PantryDaemonCommon::VERSION
  spec.authors       = ["Alex Slynko"]
  spec.email         = ["pantry@wonga.com"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"
  spec.add_dependency "net-ssh"
  spec.add_dependency "net-ssh-multi"
  spec.add_dependency "em-winrm"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
