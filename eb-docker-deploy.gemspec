# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "eb-docker-deploy"
  spec.version       = Deploy::VERSION
  spec.authors       = ["Tim", "Mike", "Deseret Book"]
  spec.email         = ["thogg4@gmail.com", "webdev@deseretbook.com"]
  spec.summary       = 'deploy with docker and aws eb'
  spec.description   = 'deploy with docker and aws eb'
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = ['ebd']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'thor'
  spec.add_dependency 'highline'

  spec.add_dependency 'aws-sdk-elasticbeanstalk', '~> 1'

  spec.add_dependency 'rubyzip', '~> 1.1.7'

  spec.add_dependency 'slack-notifier'
end
