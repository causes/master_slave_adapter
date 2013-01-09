require 'active_record/connection_adapters/master_slave_adapter/lag_strategies/prefer_slave'

module ActiveRecord::ConnectionAdapters::MasterSlaveAdapter
  module LagStrategies
    module RelaxedStrategy
      include PreferSlave

      def current_connection
        # usually this is a slave connection, when inside of with_master it is a master connection
        cur = connection_stack.first
        if slave_consistent?(cur, @config[:loose_lag] || 60)
          cur
        else
          master_connection
        end
      end
    end
  end
end
