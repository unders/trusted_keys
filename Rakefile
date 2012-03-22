#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  t.libs.push "lib"
  t.libs.push "spec"
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

task :test => :spec
task :default => :test

desc  "open console (require 'trusted_keys')"
task :c do
  system "irb -I lib -r trusted_keys"
end
