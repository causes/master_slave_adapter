shared_examples_for 'HeartbeatClock consistency' do

  it 'returns true when the slave is consistent' do
    status = []
    status[0] = {'ts' => '2013-01-16T19:42:38.001120 '}
    status[1] = {'ts' => '2013-01-16T19:42:38.001120 '}

    ActiveRecord::Base.with_slave do |conn|
      adapter_connection.send('slave_consistent?', conn, 60, status)
    end.should equal(true)
  end

  it 'returns false when the slave is not consistent' do
    status = []
    status[0] = {'ts' => '2013-01-16T19:49:38.001120 '}
    status[1] = {'ts' => '2013-01-16T19:42:38.001120 '}

    ActiveRecord::Base.with_slave do |conn|
      adapter_connection.send('slave_consistent?', conn, 60, status)
    end.should equal(false)
  end

  it 'returns false when unable to connect to slave' do
    slave_connection.stub(:connection_error?).and_return(true)
    ActiveRecord::Base.with_slave do |conn|
      adapter_connection.send('slave_consistent?', conn, 60)
    end.should equal(false)
  end
end
