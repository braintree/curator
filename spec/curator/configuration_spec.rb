require File.expand_path('../../spec_helper', __FILE__)

describe Curator::Configuration do
  before(:each) do
    @config = Curator::Configuration.new
  end

  it 'allows properties to be set dynamically' do
    lambda { @config.foobar = 'test' }.should_not raise_error(NoMethodError)
  end

  it 'allows properties to be read dynamically' do
    @config.foobar = 'test'
    @config.foobar.should == 'test'
  end

  it 'responds to dynamic properties' do
    @config.foobar = 'test'
    @config.respond_to?(:foobar).should be_true
  end

  it 'responds to existing methods' do
    @config.respond_to?(:to_s).should be_true
  end
end
