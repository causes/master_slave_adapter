$: << File.expand_path(File.join(File.dirname( __FILE__ ), '..', '..', 'lib'))

require 'rspec'
require 'common/support/connection_setup_helper'
require 'common/support/mysql_master_slave_adapter_examples'
require 'common/support/default_clock_consistency_examples'
require 'common/support/heartbeat_clock_consistency_examples'
require 'active_record/connection_adapters/mysql_master_slave_adapter'
require 'active_record/connection_adapters/master_slave_adapter/clocks/default_clock'
require 'active_record/connection_adapters/master_slave_adapter/clocks/heartbeat_clock'

module ActiveRecord
  class Base
    cattr_accessor :master_mock, :slave_mock

    def self.mysql_connection(config)
      config[:database] == 'slave' ? slave_mock : master_mock
    end
  end
end

describe ActiveRecord::ConnectionAdapters::MysqlMasterSlaveAdapter do
  context 'using HeartbeatClock' do
    let(:connection_adapter) { 'mysql' }
    let(:clock_implementation) { 'HeartbeatClock' }
    let(:lag_strategy) { 'DefaultStrategy' }
    include_context 'connection setup'

    it_should_behave_like 'HeartbeatClock consistency'
    it_should_behave_like 'mysql_master_slave_adapter'
  end

  context 'using DefaultClock' do
    let(:connection_adapter) { 'mysql' }
    let(:clock_implementation) { 'DefaultClock' }
    let(:lag_strategy) { 'DefaultStrategy' }
    include_context 'connection setup'

    it_should_behave_like 'DefaultClock consistency'
    it_should_behave_like 'mysql_master_slave_adapter'
  end
end
