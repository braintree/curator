require "spec_helper"

describe Curator::Repository::Settings do
  let(:current_settings) do
    {"allow_mult" => true, "last_write_wins" => false}
  end

  it "takes a hash of current settings" do
    settings = Curator::Repository::Settings.new(current_settings)
    settings.to_hash.should == current_settings
  end

  context "with current settings" do
    subject { Curator::Repository::Settings.new(current_settings) }

    it "updates previously defined settings" do
      subject.set("allow_mult", false)
      subject["allow_mult"].should be_false
    end

    it "sets new settings" do
      subject.set("my_new_setting", 1000)
      subject["my_new_setting"].should == 1000
    end

    it "allows symbols interchangably" do
      subject.set(:allow_mult, false)
      subject["allow_mult"].should be_false
    end

    it "disables properties" do
      subject.disable(:some_enabled_option)
      subject[:some_enabled_option].should be_false
    end

    it "enables properties" do
      subject.enable(:some_disabled_option)
      subject[:some_disabled_option].should be_true
    end
  end

  describe "dirty attributes" do
    subject { Curator::Repository::Settings.new(:allow_mult => true) }

    it "is uncommitted when new attributes are added" do
      subject.enable(:a_new_option)
      subject.should be_uncommitted
    end

    it "is uncommitted when attributes are updated" do
      subject.disable(:allow_mult)
      subject.should be_uncommitted
    end

    it "doesnt become uncommitted when attribute is updated to same value" do
      subject.enable(:allow_mult)
      subject.should_not be_uncommitted
    end

    it "is no longer uncommitted when dirty properties are cleared" do
      subject.disable(:allow_mult)
      subject.clear_dirty!
      subject.should_not be_uncommitted
    end

    describe "#changed" do
      it "includes properties that have changed" do
        subject.disable(:allow_mult)
        subject.changed.should include(:allow_mult => false)
      end

      it "doesnt return properties that haven't changed" do
        subject.enable(:allow_mult)
        subject.changed.should_not include(:allow_mult => true)
      end
    end
  end
end
