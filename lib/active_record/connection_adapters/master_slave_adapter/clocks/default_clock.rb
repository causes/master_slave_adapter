require 'active_record/connection_adapters/master_slave_adapter/clock'

module ActiveRecord
  module ConnectionAdapters
    module MasterSlaveAdapter
      module Clocks
        module DefaultClock

          def with_consistency(clock)
            super(clock)
            current_clock || clock
          end

          def slave_consistent?(conn, clock)
            self.current_clock = clock = case clock
                    when Clock
                      clock
                    when String
                      Clock.parse(clock)
                    when Fixnum
                      master_clock
                    else
                      Clock.zero
                    end

            if @clock_context[conn].try(:>=, clock)
              true
            elsif (slave_clk = slave_clock)
              @clock_context[conn] = clock
              slave_clk >= clock
            else
              false
            end
          end

          def master_clock
            conn = master_connection
            if status = conn.uncached { conn.select_one("SHOW MASTER STATUS") }
              Clock.new(status['File'], status['Position'])
            else
              Clock.infinity
            end
          rescue MasterUnavailable
            Clock.zero
          rescue ActiveRecordError
            Clock.infinity
          end

          def slave_clock
            # always use the slave connection here
            conn = connection_stack.last
            if status = conn.uncached { conn.select_one("SHOW SLAVE STATUS") }
              Clock.new(status['Relay_Master_Log_File'], status['Exec_Master_Log_Pos'])
            else
              Clock.zero
            end
          rescue ActiveRecordError
            Clock.zero
          end
        end
      end
    end
  end
end
