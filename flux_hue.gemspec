# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "flux_hue/version"

Gem::Specification.new do |spec|
  spec.name          = "flux_hue"
  spec.version       = FluxHue::VERSION
  spec.authors       = ["Jon Frisby", "Sam Soffes"]
  spec.email         = ["jfrisby@mrjoy.com", "sam@soff.es"]
  spec.description   = "Work with the Philips Hue system."
  spec.summary       = "Work with the Philips Hue system from Ruby."
  spec.homepage      = "https://github.com/MrJoy/hue"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"
  spec.add_dependency "thor"
  spec.add_dependency "json"
  spec.add_dependency "playful"
  spec.add_dependency "terminal-table"
  spec.add_development_dependency "rspec", "~> 3.3.0"
  spec.add_development_dependency "webmock"
end
