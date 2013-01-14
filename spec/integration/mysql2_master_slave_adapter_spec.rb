$: << File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))

require 'rspec'
require 'master_slave_adapter'
require 'integration/support/shared_mysql_examples'

RSpec.configure {|c| c.fail_fast = true}


describe 'ActiveRecord::ConnectionAdapters::Mysql2MasterSlaveAdapter' do
  %w[DefaultClock HeartbeatClock].each do |clock|
    context "with #{clock}" do
      %w[DefaultStrategy RelaxedStrategy].each do |strategy|
        context "using #{strategy}" do
          let(:connection_adapter) { 'mysql2' }
          let(:clock_implementation) { clock }
          let(:lag_strategy) { strategy }

          it_should_behave_like "a MySQL MasterSlaveAdapter"

        end
      end

      context 'using StrictStrategy' do
        let(:connection_adapter) { 'mysql2' }
        let(:clock_implementation) { clock }
        let(:lag_strategy) { 'StrictStrategy' }

        it_should_behave_like 'a MySQL MasterSlaveAdapter'

      end
    end
  end
end
