# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{chicago}
  s.version = "0.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roland Swingler"]
  s.date = %q{2011-01-13}
  s.email = %q{roland.swingler@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["LICENSE", "Rakefile", "README", "spec", "lib/chicago", "lib/chicago/#cube.rb#", "lib/chicago/core_ext", "lib/chicago/core_ext/array.rb", "lib/chicago/core_ext/sequel", "lib/chicago/core_ext/sequel/dataset.rb", "lib/chicago/data", "lib/chicago/data/month.rb", "lib/chicago/data/pivoted_dataset.rb", "lib/chicago/definable.rb", "lib/chicago/etl", "lib/chicago/etl/#batch.rb#", "lib/chicago/etl/#etl_table_migration.rb#", "lib/chicago/etl/#task.rb#", "lib/chicago/etl/batch.rb", "lib/chicago/etl/database_source.rb", "lib/chicago/etl/table_builder.rb", "lib/chicago/etl/task_invocation.rb", "lib/chicago/query.rb", "lib/chicago/rake_tasks.rb", "lib/chicago/schema", "lib/chicago/schema/#db_table_command.rb#", "lib/chicago/schema/column.rb", "lib/chicago/schema/column_group_builder.rb", "lib/chicago/schema/constants.rb", "lib/chicago/schema/dimension.rb", "lib/chicago/schema/fact.rb", "lib/chicago/schema/hierarchical_element.rb", "lib/chicago/schema/migration_file_writer.rb", "lib/chicago/schema/star_schema_table.rb", "lib/chicago/schema/type_converters.rb", "lib/chicago/util", "lib/chicago/util/filter_string_parser.rb", "lib/chicago/vendor", "lib/chicago/vendor/code_statistics.rb", "lib/chicago.rb"]
  s.homepage = %q{http://knaveofdiamonds.com}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Chicago}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sequel_migration_builder>, ["~> 0.2.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<sequel_migration_builder>, ["~> 0.2.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<sequel_migration_builder>, ["~> 0.2.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
