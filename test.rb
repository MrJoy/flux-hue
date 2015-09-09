#!/usr/bin/env ruby
$LOAD_PATH << Dir.pwd + "/lib"
require "yaml"
require "set"
require "ostruct"
require "sparkle_motion"
SparkleMotion.use_graph!
SparkleMotion::Config.init_lights!
SparkleMotion::Config.init_simulations!

require "pp"

def header(msg)
  puts "#{msg} #{'=' * (80 - (msg.length + 1))}"
end

def gap
  puts
  puts
  puts
end

header "Bridges"
SparkleMotion::Config.bridges.each do |bridge|
  puts "  #{bridge.name}:"
  puts "    * ip:           #{bridge.ip}"
  puts "    * username:     #{bridge.username}"
  puts "    * max_connects: #{bridge.max_connects}"
  puts "    * debug_hue:    #{bridge.debug_hue}"
end
gap

header "Lights"
SparkleMotion::Config.lights.each do |light|
  puts "  #{light.name}:"
  puts "    * bridge: #{light.bridge}"
  puts "    * index:  #{light.index}"
end
gap

header "Groups"
SparkleMotion::Config.groups.each do |group|
  puts "  #{group.name}: #{group.lights.sort.join(', ')}"
end
gap

header "Simulations"
SparkleMotion::Config.simulations.each do |simulation|
  puts "  #{simulation.name}:"
  color_bender = simulation.color_bender
  if color_bender
    puts "    color_bender:"
    puts "      transition: #{color_bender.transition}"
    puts "      values:     #{color_bender.values.sort.join(', ')}"
  end
  puts "    nodes:"
  nodes = simulation.nodes
  if nodes
    nodes.each do |_, node|
      if node.respond_to?(:source)
        puts "      #{node.name} << #{node.source.name}"
      else
        puts "      #{node.name}"
      end
    end
  end
  puts "    output: << #{simulation.output.source.name}"
end
gap
