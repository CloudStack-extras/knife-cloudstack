# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-cs/version'

Gem::Specification.new do |spec|
  spec.name          = "knife-cloudstack"
  spec.version       = Knife::Cloudstack::VERSION
  spec.authors       = ["Sander Botman"]
  spec.email         = ["sbotman@schubergphilis.com"]
  spec.summary       = %q{CloudStack Support for Chef's Knife Command}
  spec.description   = %q{CloudStack Support for Chef's Knife Command using knife-cloud}
  spec.homepage      = ""
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency "fog", ">= 1.10.0"
  spec.add_dependency "chef", ">= 0.10.10"
  spec.add_dependency "knife-windows"
end
