require "spec_helper"
require "curator/settings_updater"

describe Curator::SettingsUpdater do
  subject { Curator::SettingsUpdater.new(Curator.repositories, :verbose => false) }
  let(:mock_repository) { mock }

  before do
    Curator.stub(:repositories).and_return([mock_repository])
  end

  it "updates settings for repositories with uncommitted settings" do
    mock_repository.stub(:settings_uncommitted?).and_return(true)
    mock_repository.should_receive(:apply_settings!)
    subject.run!
  end

  it "skips repositories without uncommitted settings" do
    mock_repository.stub(:settings_uncommitted?).and_return(false)
    mock_repository.should_not_receive(:apply_settings!)
    subject.run!
  end

  it "uses loaded repositories" do
    repositories = Curator::SettingsUpdater.new.repositories
    repositories.should == Curator.repositories
  end
end
