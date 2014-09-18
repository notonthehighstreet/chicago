# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name              = "chicagowarehouse"
  gem.version           = "0.6.7"
  gem.summary           = "Ruby Data Warehousing"
  gem.description       = "Simple Data Warehouse toolkit for ruby"
  gem.author            = "Roland Swingler"
  gem.email             = "roland.swingler@gmail.com"
  gem.has_rdoc          = true
  gem.license           = "MIT"
  gem.homepage          = "http://github.com/notonthehighstreet/chicago"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rcov = true
  spec.rcov_opts = "-x spec/ -x /home"
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

desc "Flog this baby!"
task :flog do
  sh 'find lib -name "*.rb" | xargs flog -m'
end

load 'tasks/stats.rake'
