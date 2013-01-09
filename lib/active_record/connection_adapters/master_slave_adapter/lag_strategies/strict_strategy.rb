require 'active_record/connection_adapters/master_slave_adapter/lag_strategies/prefer_slave'

class ActiveRecord::LagException < ActiveRecord::ActiveRecordError; end

module ActiveRecord::ConnectionAdapters::MasterSlaveAdapter
  module LagStrategies
    module StrictStrategy
      include PreferSlave

      def with_consistency(clock = nil)
        # try random slave, else failure
        slave = slave_connection!
        conn =
          if !open_transaction? && slave_consistent?(slave, clock)
            slave
          else
            raise ActiveRecord::LagException
          end

        with(conn) { yield }
      end

      def current_connection
        cur = connection_stack.first
        if slave_consistent?(cur, @config[:loose_lag] || 60)
          cur
        else
          raise ActiveRecord::LagException
        end
      end
    end
  end
end
