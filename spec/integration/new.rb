require 'fileutils'
require 'erb'

FILES_DIR = File.join(File.dirname(__FILE__), 'tests')
FileUtils.mkdir_p FILES_DIR

TPL = <<-EOF
$: << File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))

require 'rspec'
require 'master_slave_adapter'
require 'integration/support/shared_mysql_examples'
require 'integration/support/shared_mysql_examples_default'
require 'integration/support/shared_mysql_examples_strict'

RSpec.configure {|c| c.fail_fast = true}

describe 'ActiveRecord::ConnectionAdapters::Mysql2MasterSlaveAdapter' do
  context 'with <%= clock %>' do
    context 'with <%= strategy %>' do
      let(:connection_adapter) { '<%= adapter %>' }
      let(:clock_implementation) { '<%= clock %>' }
      let(:lag_strategy) { '<%= strategy %>' }

      it_should_behave_like "a MySQL MasterSlaveAdapter"
      <%- if strategy == 'StrictStrategy' -%>
      it_should_behave_like "a StrictStrategy"
      <%- else -%>
      it_should_behave_like "a DefaultStrategy"
      <%- end -%>
    end
  end
end
EOF


%w[mysql mysql2].each do |adapter|
  %w[DefaultClock HeartbeatClock].each do |clock|
    %w[DefaultStrategy RelaxedStrategy].each do |strategy|
      erb = ERB.new(TPL, nil, '-')
      File.open(File.join(FILES_DIR, "#{adapter}_#{clock}_#{strategy}_spec.rb"), 'w') do |fd|
        fd.write(erb.result(binding))
      end
    end

    strategy = 'StrictStrategy'
    erb = ERB.new(TPL, nil, '-')
    File.open(File.join(FILES_DIR, "#{adapter}_#{clock}_#{strategy}_spec.rb"), 'w') do |fd|
      fd.write(erb.result(binding))
    end
  end
end
