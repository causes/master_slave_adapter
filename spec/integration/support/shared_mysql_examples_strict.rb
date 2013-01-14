require 'integration/support/mysql_setup_helper'

shared_examples_for "a StrictStrategy" do
  include MysqlSetupHelper

  let(:configuration) do
    {
      :adapter => 'master_slave',
      :connection_adapter => connection_adapter,
      :clock_implementation => clock_implementation,
      :lag_strategy => lag_strategy,
      :username => 'root',
      :database => 'master_slave_adapter',
      :master => {
        :host => '127.0.0.1',
        :port => port(:master),
      },
      :slaves => [{
        :host => '127.0.0.1',
        :port => port(:slave),
      }],
    }
  end

  let(:test_table) { MysqlSetupHelper::TEST_TABLE }

  let(:logger) { nil }

  def connection
    ActiveRecord::Base.connection
  end

  def should_read_from(host)
    server = server_id(host)
    query  = "SELECT @@Server_id as Value"

    connection.select_all(query).first["Value"].to_s.should == server
    connection.select_one(query)["Value"].to_s.should == server
    connection.select_rows(query).first.first.to_s.should == server
    connection.select_value(query).to_s.should == server
    connection.select_values(query).first.to_s.should == server
  end

  before(:all) do
    setup
    start_master
    start_slave
    configure
    start_replication
  end

  after(:all) do
    stop_master
    stop_slave
  end

  before do
    ActiveRecord::Base.establish_connection(configuration)
    ActiveRecord::Base.logger = logger
    ActiveRecord::Base.connection.should be_active
  end

  context "when asked for consistency" do
    context "given slave is fully synced" do
      before do
        wait_for_replication_sync
      end

      it "reads from slave" do
        ActiveRecord::Base.with_consistency(2) do
          should_read_from :slave
        end
      end
    end

    context "given slave lags behind" do
      before do
        stop_replication
        move_master_clock
        sleep 3
      end

      after do
        start_replication
      end

      it "fails" do
        expect do
          ActiveRecord::Base.with_consistency(2) do
            should_read_from :master
          end
        end.to raise_error(ActiveRecord::LagException)
      end

      context "and slave catches up" do
        before do
          start_replication
          wait_for_replication_sync
        end

        it "reads from slave" do
          ActiveRecord::Base.with_consistency(2) do
            should_read_from :slave
          end
        end
      end
    end

    context "given we always wait for slave to catch up and be consistent" do
      before do
        start_replication
      end

      it "should always read from slave" do
        wait_for_replication_sync
        ActiveRecord::Base.with_consistency(2) do
          should_read_from :slave
        end
        move_master_clock
        wait_for_replication_sync
        ActiveRecord::Base.with_consistency(2) do
          should_read_from :slave
        end
      end
    end
  end
end
