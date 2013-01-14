shared_examples_for 'mysql_master_slave_adapter' do
  describe "connection error detection" do
    {
      Mysql::Error::CR_CONNECTION_ERROR   => "query: not connected",
      Mysql::Error::CR_CONN_HOST_ERROR    => "Can't connect to MySQL server on 'localhost' (3306)",
      Mysql::Error::CR_SERVER_GONE_ERROR  => "MySQL server has gone away",
      Mysql::Error::CR_SERVER_LOST        => "Lost connection to MySQL server during query",
    }.each do |errno, description|
      it "raises MasterUnavailable for '#{description}' during query execution" do
        master_connection.stub_chain(:raw_connection, :errno).and_return(errno)
        master_connection.should_receive(:insert).and_raise(ActiveRecord::StatementInvalid.new("Mysql::Error: #{description}: INSERT 42"))

        expect do
          adapter_connection.insert("INSERT 42")
        end.to raise_error(ActiveRecord::MasterUnavailable)
      end

      it "doesn't raise anything for '#{description}' during connection" do
        error = Mysql::Error.new(description)
        error.stub(:errno).and_return(errno)
        ActiveRecord::Base.should_receive(:master_mock).and_raise(error)

        expect do
          ActiveRecord::Base.connection_handler.clear_all_connections!
          ActiveRecord::Base.connection
        end.to_not raise_error
      end
    end

    it "raises StatementInvalid for other errors" do
      error = ActiveRecord::StatementInvalid.new("Mysql::Error: Query execution was interrupted: INSERT 42")
      master_connection.stub_chain(:raw_connection, :errno).and_return(Mysql::Error::ER_QUERY_INTERRUPTED)
      master_connection.should_receive(:insert).and_raise(error)

      expect do
        adapter_connection.insert("INSERT 42")
      end.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
