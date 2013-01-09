module ActiveRecord
  module ConnectionAdapters
    module MasterSlaveAdapter
      module LagStrategies
        module PreferSlave
          [
            :insert,
            :update,
            :delete,
            :execute,
            :commit_db_transaction,
            :rollback_db_transaction
          ].each do |meth|
            define_method meth do |*args| # e.g. def insert(*args)
              begin
                super(*args)
              ensure
                connection_stack.replace([slave_connection!])
              end
            end
          end
        end
      end
    end
  end
end
