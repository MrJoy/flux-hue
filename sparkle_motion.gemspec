# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "sparkle_motion/version"

Gem::Specification.new do |s|
  s.name                  = "sparkle_motion"
  s.version               = SparkleMotion::VERSION
  s.author                = "Jon Frisby"
  s.email                 = "jfrisby@mrjoy.com"
  s.homepage              = "http://github.com/MrJoy/sparkle_motion"
  s.description           = "A system for generative event lighting using Philips Hue controlled"\
                              " from a Novation Launchpad"
  s.summary               = "Generative event lighting using Philips Hue, and Novation Launchpad"
  raw_file_list           = `git ls-files`.split("\n")
  s.files                 = raw_file_list
                            .reject do |fname|
                              fname =~ %r{
                                \A
                                (\..*
                                |Gemfile.*
                                |notes/.*
                                |tasks/.*
                                |tmp/.*
                                |Rakefile
                                |.*\.sublime-project
                                )
                                \z
                              }x
                            end
  s.test_files            = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables           = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.extra_rdoc_files      = %w(CHANGELOG.md README.md LICENSE)
  s.require_paths         = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0")

  s.add_dependency "oj"
  s.add_dependency "rgb"
  s.add_dependency "curb"
  s.add_dependency "perlin_noise"
  s.add_dependency "logger-better"
  s.add_dependency "frisky"
  s.add_dependency "mrjoy-launchpad"
end
