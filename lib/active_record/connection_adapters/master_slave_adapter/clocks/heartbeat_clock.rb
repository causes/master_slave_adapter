require 'date'

module ActiveRecord::ConnectionAdapters::MasterSlaveAdapter
  module Clocks
    module HeartbeatClock
      MASTER = 1
      SLAVE = 0
      QUERY = <<-EOF
      SELECT
        "slave" AS type,
        ts,
        relay_master_log_file AS file,
        exec_master_log_pos AS pos
      FROM
        heartbeat.heartbeat
      WHERE
        server_id = @@server_id
      UNION ALL SELECT
        "master" AS type,
        ts,
        relay_master_log_file AS file,
        exec_master_log_pos AS pos
      FROM
        heartbeat.heartbeat
      WHERE
        relay_master_log_file IS NULL
      EOF

      def get_status(conn)
        conn.uncached { conn.select_all(QUERY) } rescue nil
      end

      def date_diff_as_seconds(t1, t2)
        ((t1 - t2) * 24 * 60 * 60).to_i
      end

      def date_diff_from_timestamps(ts1, ts2)
        date_diff_as_seconds(DateTime.parse(ts1), DateTime.parse(ts2))
      end

      def slave_consistent?(conn, max_lag, status = nil)
        if max_lag.nil?
          max_lag = @config[:strict_lag] || 1
        end

        @clock_context[:last_updated_at] ||= Time.at(0)
        return true if Time.now <= @clock_context[:last_updated_at] + max_lag
        return false unless status ||= get_status(conn)
        return false if status.length != 2

        date_diff = date_diff_from_timestamps(
          status[SLAVE]['ts'],
          status[MASTER]['ts']
        )

        if return_val = date_diff < max_lag
          @clock_context[:last_updated_at] = Time.now
        end

        return_val
      end

      def master_clock
        nil
      end

      def slave_clock
        nil
      end
    end
  end
end
