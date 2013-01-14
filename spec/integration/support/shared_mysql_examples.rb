require 'integration/support/mysql_setup_helper'

shared_examples_for "a MySQL MasterSlaveAdapter" do
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

  it "connects to the database" do
    expect { ActiveRecord::Base.connection }.to_not raise_error
  end

  context "given a debug logger" do
    let(:logger) do
      logger = []
      def logger.debug(*args)
        push(args.join)
      end
      def logger.debug?
        true
      end

      logger
    end

    it "logs the connection info" do
      ActiveRecord::Base.connection.select_value("SELECT 42")

      logger.last.should =~ /\[slave:127.0.0.1:3311\] SQL .*SELECT 42/
    end
  end

  context "when asked for master" do
    it "reads from master" do
      ActiveRecord::Base.with_master do
        should_read_from :master
      end
    end
  end

  context "when asked for slave" do
    it "reads from slave" do
      ActiveRecord::Base.with_slave do
        should_read_from :slave
      end
    end
  end

  context "given master goes away in between queries" do
    let(:query) { "INSERT INTO #{test_table} (message) VALUES ('test')" }

    after do
      start_master
    end

    it "raises a MasterUnavailable exception" do
      expect do
        ActiveRecord::Base.connection.insert(query)
      end.to_not raise_error

      stop_master

      expect do
        ActiveRecord::Base.connection.insert(query)
      end.to raise_error(ActiveRecord::MasterUnavailable)
    end
  end

  context "given master is not available" do
    before do
      stop_master
    end

    after do
      start_master
    end

    context "when asked for master" do
      it "fails" do
        expect do
          ActiveRecord::Base.with_master { should_read_from :master }
        end.to raise_error(ActiveRecord::MasterUnavailable)
      end
    end

    context "when asked for slave" do
      it "reads from slave" do
        ActiveRecord::Base.with_slave do
          should_read_from :slave
        end
      end
    end
  end

  context "given slave is not available" do
    before do
      stop_slave
    end

    after do
      start_slave
    end

    context "when asked for slave" do
      it "returns the master" do
        expect do
          ActiveRecord::Base.with_slave { should_read_from :master }
        end
      end
    end
  end
end
