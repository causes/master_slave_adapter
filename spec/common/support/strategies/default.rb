shared_examples_for 'DefaultStrategy' do
  describe 'select behavior' do
    SelectMethods.each do |method|
      it "should send the method '#{method}' to the slave connection" do
        master_connection.stub!( :open_transactions ).and_return( 0 )
        slave_connection.should_receive( method ).with('testing').and_return( true )
        adapter_connection.send( method, 'testing' )
      end

      it "should send the method '#{method}' to the slave connection if with_slave was specified" do
        slave_connection.should_receive( method ).with('testing').and_return( true )
        ActiveRecord::Base.with_slave do
          adapter_connection.send( method, 'testing' )
        end
      end

      context 'given slave is not available' do
        it 'raises statement invalid exception' do
          adapter_connection.stub(:connection_error?).and_return(true)
          slave_connection.should_receive(method).with('testing').and_raise(ActiveRecord::StatementInvalid)

          expect do
            ActiveRecord::Base.with_slave do
              adapter_connection.send(method, 'testing')
            end
          end.to raise_error(ActiveRecord::StatementInvalid)
        end
      end
    end # /SelectMethods.each
  end

  describe "query cache" do
    describe "#cache" do
      it "activities query caching on all connections" do
        master_connection.should_receive(:cache).and_yield
        slave_connection.should_receive(:cache).and_yield
        master_connection.should_not_receive(:select_value)
        slave_connection.should_receive(:select_value)

        adapter_connection.cache do
          adapter_connection.select_value("SELECT 42")
        end
      end
    end

    describe "#uncached" do
      it "deactivates query caching on all connections" do
        master_connection.should_receive(:uncached).and_yield
        slave_connection.should_receive(:uncached).and_yield
        master_connection.should_not_receive(:select_value)
        slave_connection.should_receive(:select_value)

        adapter_connection.uncached do
          adapter_connection.select_value("SELECT 42")
        end
      end
    end
  end

  describe "connection stack" do
    it "should start with the slave connection on top" do
      adapter_connection.current_connection.should == slave_connection
    end
  end
end
