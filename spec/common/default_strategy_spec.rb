$: << File.expand_path(File.join(File.dirname( __FILE__ ), '..', '..', 'lib'))

require 'rspec'
require 'common/support/connection_setup_helper'
require 'common/support/strategies/default'
require 'common/support/master_slave_adapter_examples'
require 'active_record/connection_adapters/master_slave_adapter/lag_strategies/default_strategy'
require 'active_record/connection_adapters/master_slave_adapter/clocks/default_clock'
require 'active_record/connection_adapters/master_slave_adapter/clocks/heartbeat_clock'

module ActiveRecord
  class Base
    cattr_accessor :master_mock, :slave_mock

    def self.test_connection(config)
      config[:database] == 'slave' ? slave_mock : master_mock
    end

    def self.test_master_slave_connection(config)
      ConnectionAdapters::TestMasterSlaveAdapter.new(config, logger)
    end
  end

  module ConnectionAdapters
    class TestMasterSlaveAdapter < AbstractAdapter
      include MasterSlaveAdapter

      def slave_consistent(*args)
        true
      end

      def slave_inconsistent(*args)
        false
      end

      def master_clock
      end

      def slave_clock(connection)
      end

      def connection_error?(exception)
      end
    end
  end
end

describe ActiveRecord::ConnectionAdapters::MasterSlaveAdapter do
  context 'using DefaultStrategy' do
    context 'with consistency' do
      before do
        class ActiveRecord::ConnectionAdapters::TestMasterSlaveAdapter
          alias :slave_consistent? :slave_consistent
        end
      end

      let(:connection_adapter) { 'test' }
      let(:clock_implementation) { 'DefaultClock' }
      let(:lag_strategy) { 'DefaultStrategy' }
      include_context 'connection setup'


      it_should_behave_like 'master_slave_adapter'
      it_should_behave_like 'DefaultStrategy'

      describe "connection stack" do
        it "should start with the slave connection on top" do
          adapter_connection.current_connection.should == slave_connection
        end

        it "should continue to use master connection after a write" do
          master_connection.should_receive(:execute).with("INSERT 42")

          ActiveRecord::Base.with_slave do
            adapter_connection.current_connection.should == slave_connection
            ActiveRecord::Base.with_master do
              adapter_connection.current_connection.should == master_connection
              ActiveRecord::Base.with_slave do
                adapter_connection.current_connection.should == slave_connection
                adapter_connection.execute("INSERT 42")
                adapter_connection.current_connection.should == master_connection
              end
              adapter_connection.current_connection.should == master_connection
            end
            adapter_connection.current_connection.should == master_connection
          end
          adapter_connection.current_connection.should == master_connection
        end
      end
    end

    context 'without consistency' do
      before do
        class ActiveRecord::ConnectionAdapters::TestMasterSlaveAdapter
          alias :slave_consistent? :slave_inconsistent
        end
      end
      let(:connection_adapter) { 'test' }
      let(:clock_implementation) { 'DefaultClock' }
      let(:lag_strategy) { 'DefaultStrategy' }
      include_context 'connection setup'

      it_should_behave_like 'master_slave_adapter'
      it_should_behave_like 'DefaultStrategy'
      describe "connection stack" do
        it "should start with the slave connection on top" do
          adapter_connection.current_connection.should == slave_connection
        end

        it "should continue to use master connection after a write" do
          master_connection.should_receive(:execute).with("INSERT 42")

          ActiveRecord::Base.with_slave do
            adapter_connection.current_connection.should == slave_connection
            ActiveRecord::Base.with_master do
              adapter_connection.current_connection.should == master_connection
              ActiveRecord::Base.with_slave do
                adapter_connection.current_connection.should == slave_connection
                adapter_connection.execute("INSERT 42")
                adapter_connection.current_connection.should == master_connection
              end
              adapter_connection.current_connection.should == master_connection
            end
            adapter_connection.current_connection.should == master_connection
          end
          adapter_connection.current_connection.should == master_connection
        end
      end
    end
  end
end
