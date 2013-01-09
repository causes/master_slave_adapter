require 'active_record/connection_adapters/master_slave_adapter/clock'

module ActiveRecord::ConnectionAdapters::MasterSlaveAdapter
  module LagStrategies
    module DefaultStrategy

    protected

      def on_write
        with(master_connection) do |conn|
          yield(conn).tap do
            unless open_transaction?
              master_clk = master_clock
              unless current_clock.try(:>=, master_clk)
                self.current_clock = master_clk
              end

              # keep using master after write
              connection_stack.replace([ conn ])
            end
          end
        end
      end
    end
  end
end
