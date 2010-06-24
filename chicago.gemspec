# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{chicago}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roland Swingler"]
  s.date = %q{2010-06-22}
  s.email = %q{roland.swingler@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["LICENSE", "Rakefile", "README", "spec", "lib/chicago", "lib/chicago/column.rb", "lib/chicago/dimension.rb", "lib/chicago/fact.rb", "lib/chicago/migration_file_writer.rb", "lib/chicago/schema", "lib/chicago/schema/#db_table_command.rb#", "lib/chicago/schema/column_group_builder.rb", "lib/chicago/schema/type_converters.rb", "lib/chicago/schema.rb", "lib/chicago/star_schema_table.rb", "lib/chicago.rb", "lib/dump.rb", "lib/tasks", "lib/tasks/stats.rake"]
  s.homepage = %q{http://knaveofdiamonds.com}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Chicago}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sequel_migration_builder>, ["~> 0.0.4"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<sequel_migration_builder>, ["~> 0.0.4"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<sequel_migration_builder>, ["~> 0.0.4"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
