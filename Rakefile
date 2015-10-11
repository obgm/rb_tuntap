require "bundler/gem_tasks"
require 'rake/extensiontask'

# Rake::ExtensionTask.new('rb_tuntap_ext')

task :default => ['lib/rb_tuntap/rb_tuntap_constants.rb']

file 'lib/rb_tuntap/rb_tuntap_constants.rb' => ['lib/rb_tuntap/rb_tuntap_make_constants.rb'] do |t|
  sh "ruby #{t.source} > #{t.name}"
end

desc "Open an irb session preloaded with this library"
task :console do
  top_dir = File.dirname(__FILE__)
  lib_dir = File.join(top_dir, 'lib')

  exec "irb -I #{lib_dir} -r rb_tuntap -r irb/completion"
end
