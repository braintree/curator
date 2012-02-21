require 'spec_helper'

describe Curator do
  describe 'self.configure' do
    it 'creates a configuration if one does not exist' do
      old_config = Curator.config
      Curator.instance_variable_set(:@config, nil)
      Curator.configure(:riak)
      Curator.config.should be_kind_of(Curator::Configuration)
      Curator.instance_variable_set(:@config, old_config)
    end

    it 'leaves existing configuration in place' do
      Curator.configure(:riak)
      old_config = Curator.config
      Curator.configure(:riak)
      Curator.config.should equal(old_config)
    end

    it 'takes a block and passes the configuration' do
      block_config = nil
      Curator.configure(:riak) do |config|
        block_config = config
      end

      block_config.should_not be_nil
      block_config.should equal Curator.config
    end
  end
end
