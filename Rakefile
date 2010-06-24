require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require "rake/gempackagetask"
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Chicago #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Flog this baby!"
task :flog do
  sh 'find lib -name "*.rb" | xargs flog'
end

load 'lib/tasks/stats.rake'

task :default => :spec

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|
  s.name              = "chicago"
  s.version           = "0.0.1"
  s.summary           = "Chicago"
  s.author            = "Roland Swingler"
  s.email             = "roland.swingler@gmail.com"
  s.homepage          = "http://knaveofdiamonds.com"
  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README)
  s.rdoc_options      = %w(--main README)
  s.files             = %w(LICENSE Rakefile README) + Dir.glob("{spec,lib/**/*}")
  s.require_paths     = ["lib"]
  s.add_dependency("sequel_migration_builder", "~> 0.0.4")
  s.add_development_dependency("rspec")
end

# This task actually builds the gem.
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

task :package => :gemspec

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
