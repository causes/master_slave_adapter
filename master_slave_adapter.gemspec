$:.push File.expand_path("../lib", __FILE__)

require 'active_record/connection_adapters/master_slave_adapter/version'

Gem::Specification.new do |s|
  s.name        = 'master_slave_adapter'
  s.version     = ActiveRecord::ConnectionAdapters::MasterSlaveAdapter::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ 'Mauricio Linhares', 'Torsten Curdt', 'Kim Altintop', 'Omid Aladini', 'Tiago Loureiro', 'Tobias Schmidt', 'SoundCloud' ]
  s.email       = %q{tiago@soundcloud.com ts@soundcloud.com}
  s.homepage    = 'http://github.com/soundcloud/master_slave_adapter'
  s.summary     = %q{Replication Aware Master/Slave Database Adapter for ActiveRecord}
  s.description = %q{(MySQL) Replication Aware Master/Slave Database Adapter for ActiveRecord}

  s.files        = %w[
    .gitignore
    .rspec
    .travis.yml
    CHANGELOG.md
    LICENSE
    Rakefile
    Readme.md
    lib/active_record/connection_adapters/master_slave_adapter.rb
    lib/active_record/connection_adapters/master_slave_adapter/circuit_breaker.rb
    lib/active_record/connection_adapters/master_slave_adapter/clock.rb
    lib/active_record/connection_adapters/master_slave_adapter/clocks/default_clock.rb
    lib/active_record/connection_adapters/master_slave_adapter/clocks/heartbeat_clock.rb
    lib/active_record/connection_adapters/master_slave_adapter/lag_strategies/default_strategy.rb
    lib/active_record/connection_adapters/master_slave_adapter/lag_strategies/prefer_slave.rb
    lib/active_record/connection_adapters/master_slave_adapter/lag_strategies/relaxed_strategy.rb
    lib/active_record/connection_adapters/master_slave_adapter/lag_strategies/strict_strategy.rb
    lib/active_record/connection_adapters/master_slave_adapter/version.rb
    lib/active_record/connection_adapters/mysql2_master_slave_adapter.rb
    lib/active_record/connection_adapters/mysql_master_slave_adapter.rb
    lib/master_slave_adapter.rb
    master_slave_adapter.gemspec
    spec/all.sh
    spec/common/circuit_breaker_spec.rb
    spec/common/default_strategy_spec.rb
    spec/common/mysql2_master_slave_adapter_spec.rb
    spec/common/mysql_master_slave_adapter_spec.rb
    spec/common/relaxed_strategy_spec.rb
    spec/common/strict_strategy_spec.rb
    spec/common/support/connection_setup_helper.rb
    spec/common/support/default_clock_consistency_examples.rb
    spec/common/support/heartbeat_clock_consistency_examples.rb
    spec/common/support/master_slave_adapter_examples.rb
    spec/common/support/mysql2_master_slave_adapter_examples.rb
    spec/common/support/mysql_master_slave_adapter_examples.rb
    spec/common/support/strategies/default.rb
    spec/gemfiles/activerecord2.3
    spec/gemfiles/activerecord3.0
    spec/gemfiles/activerecord3.2
    spec/integration/mysql2_master_slave_adapter_spec.rb
    spec/integration/mysql_master_slave_adapter_spec.rb
    spec/integration/new.rb
    spec/integration/support/mysql_setup_helper.rb
    spec/integration/support/shared_mysql_examples.rb
    spec/integration/support/shared_mysql_examples_default.rb
    spec/integration/support/shared_mysql_examples_strict.rb
  ]

  s.test_files   = %w[
    spec/all.sh
    spec/common/circuit_breaker_spec.rb
    spec/common/default_strategy_spec.rb
    spec/common/mysql2_master_slave_adapter_spec.rb
    spec/common/mysql_master_slave_adapter_spec.rb
    spec/common/relaxed_strategy_spec.rb
    spec/common/strict_strategy_spec.rb
    spec/common/support/connection_setup_helper.rb
    spec/common/support/default_clock_consistency_examples.rb
    spec/common/support/heartbeat_clock_consistency_examples.rb
    spec/common/support/master_slave_adapter_examples.rb
    spec/common/support/mysql2_master_slave_adapter_examples.rb
    spec/common/support/mysql_master_slave_adapter_examples.rb
    spec/common/support/strategies/default.rb
    spec/gemfiles/activerecord2.3
    spec/gemfiles/activerecord3.0
    spec/gemfiles/activerecord3.2
    spec/integration/mysql2_master_slave_adapter_spec.rb
    spec/integration/mysql_master_slave_adapter_spec.rb
    spec/integration/new.rb
    spec/integration/support/mysql_setup_helper.rb
    spec/integration/support/shared_mysql_examples.rb
    spec/integration/support/shared_mysql_examples_default.rb
    spec/integration/support/shared_mysql_examples_strict.rb
  ]

  s.executables  = []

  s.require_path = 'lib'

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = '>= 1.3.7'

  s.add_dependency 'activerecord', ['>= 4.0', '< 5.0']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
