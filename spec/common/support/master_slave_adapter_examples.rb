shared_examples_for 'master_slave_adapter' do
  include_context 'connection setup'
  let(:connection_adapter) { 'test' }

  describe 'common configuration' do
    it "should call 'columns' on master" do
      master_connection.should_receive(:columns)
      adapter_connection.columns
    end

    SelectMethods.each do |method|

      it "should send the method '#{method}' to the master connection if with_master was specified" do
        master_connection.should_receive( method ).with('testing').and_return( true )
        ActiveRecord::Base.with_master do
          adapter_connection.send( method, 'testing' )
        end
      end

      context "given there are open transactions" do
        it "should send the method '#{method}' to the master connection" do
          master_connection.stub!( :open_transactions ).and_return( 1 )
          master_connection.should_receive( method ).with('testing').and_return( true )

          adapter_connection.send( method, 'testing' )
        end

        it "should send the method '#{method}' to the master connection, even in with_slave" do
          master_connection.stub!( :open_transactions ).and_return( 1 )
          master_connection.should_receive( method ).with('testing').and_return( true )

          ActiveRecord::Base.with_slave do
            adapter_connection.send( method, 'testing' )
          end
        end

        it "raises MasterUnavailable if master is not available" do
          adapter_connection.stub(:connection_error?).and_return(true)
          master_connection.stub(:open_transactions).and_return(1)
          master_connection.should_receive(method).with('testing').and_raise(ActiveRecord::StatementInvalid)

          expect do
            adapter_connection.send(method, 'testing')
          end.to raise_error(ActiveRecord::MasterUnavailable)
        end
      end
    end # /SelectMethods.each

    SchemaStatements.each do |method|
      it "should send the method '#{method}' from ActiveRecord::ConnectionAdapters::SchemaStatements to the master"  do
        master_connection.should_receive( method ).and_return( true )
        adapter_connection.send( method )
      end

      it "should raise MasterSlaveAdapter if master is not available" do
        adapter_connection.stub(:connection_error?).and_return(true)
        master_connection.should_receive(method).and_raise(ActiveRecord::StatementInvalid)

        expect do
          adapter_connection.send(method)
        end.to raise_error(ActiveRecord::MasterUnavailable)
      end
    end

    it "should call #visitor on master connection" do
      master_connection.should_receive(:visitor)
      adapter_connection.visitor
    end

    it 'should be a master slave connection' do
      adapter_connection.class.should == ActiveRecord::ConnectionAdapters::TestMasterSlaveAdapter
    end

    it 'should have a master connection' do
      adapter_connection.master_connection.should == master_connection
    end

    it 'should have a slave connection' do
      adapter_connection.slave_connection!.should == slave_connection
    end
  end

  describe "connection testing" do
    before do
      master_connection.unstub(:active?)
      slave_connection.unstub(:active?)
    end

    context "disabled" do
      let(:database_setup) do
        default_database_setup.merge(:disable_connection_test => 'true')
      end

      it "should not perform the testing" do
        master_connection.should_not_receive(:active?)
        slave_connection.should_not_receive(:active?)

        adapter_connection.active?.should == true
      end
    end

    context "enabled" do
      it "should perform the testing" do
        # twice == one during connection + one on explicit #active? call
        master_connection.should_receive(:active?).twice.and_return(true)
        slave_connection.should_receive(:active?).twice.and_return(true)

        adapter_connection.active?.should == true
      end
    end
  end

  describe 'with connection eager loading enabled' do
    it 'should eager load the connections' do
      adapter_connection.connections.should include(master_connection, slave_connection)
    end
  end

  describe "transaction callbacks" do
    def run_tx
      adapter_connection.
        should_receive('master_clock').at_most(1).times.
          and_return(1)
      %w(begin_db_transaction
         commit_db_transaction
         increment_open_transactions
         decrement_open_transactions).each do |txstmt|
        master_connection.
          should_receive(txstmt).exactly(1).times
      end
      master_connection.
        should_receive('open_transactions').exactly(4).times.
        and_return(0, 1, 0, 0)

      master_connection.
        should_receive('update').with('testing').
        and_return(true)

      ActiveRecord::Base.transaction do
        adapter_connection.send('update', 'testing')
      end
    end

    def fail_tx
      %w(begin_db_transaction
         rollback_db_transaction
         increment_open_transactions
         decrement_open_transactions).each do |txstmt|
        master_connection.
          should_receive(txstmt).exactly(1).times
      end

      master_connection.
        should_receive('open_transactions').exactly(3).times.
        and_return(0, 1, 0)
      master_connection.
        should_receive('update').with('testing').
        and_return(true)

      ActiveRecord::Base.transaction do
        adapter_connection.send('update', 'testing')
        raise "rollback"
      end
    rescue
      nil
    end

    context "on commit" do
      it "on_commit callback should be called" do
        x = false
        adapter_connection.on_commit { x = true }
        lambda { run_tx }.should change { x }.to(true)
      end

      it "on_rollback callback should not be called" do
        x = false
        adapter_connection.on_rollback { x = true }
        lambda { run_tx }.should_not change { x }
      end
    end

    context "on rollback" do
      it "on_commit callback should not be called" do
        x = false
        adapter_connection.on_commit { x = true }
        lambda { fail_tx }.should_not change { x }
      end

      it "on_rollback callback should be called" do
        x = false
        adapter_connection.on_rollback { x = true }
        lambda { fail_tx }.should change { x }.to(true)
      end
    end
  end

  describe "connection stack" do
    it "should start with the slave connection on top" do
      adapter_connection.current_connection.should == slave_connection
    end

    it "should keep the current connection on top" do
      ActiveRecord::Base.with_master do
        adapter_connection.current_connection.should == master_connection
        ActiveRecord::Base.with_slave do
          adapter_connection.current_connection.should == slave_connection
          ActiveRecord::Base.with_master do
            adapter_connection.current_connection.should == master_connection
          end
          adapter_connection.current_connection.should == slave_connection
        end
        adapter_connection.current_connection.should == master_connection
      end
      adapter_connection.current_connection.should == slave_connection
    end
  end
end
