# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rb_tuntap/version'

Gem::Specification.new do |spec|
  spec.name          = "rb_tuntap"
  spec.version       = RbTunTap::VERSION::STRING
  spec.authors       = ["Akshay Moghe", "Carsten Bormann", "Olaf Bergmann"]
  spec.email         = ["akshay.moghe@gmail.com", "cabo@tzi.org", "bergmann@tzi.org"]
  spec.summary       = "Ruby library for working with tun/tap devices, forked for OSX."
  spec.description   = ("This library allows you to create and interact with " \
                        "TUN/TAP devices using Ruby. See the README for a " \
                        "detailed description of how to use it.")
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.platform      = Gem::Platform.local

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "RubyInline", "~> 3.12.4"
  spec.add_development_dependency "rake-compiler"
  spec.add_dependency('os', '~> 1.0')
end
