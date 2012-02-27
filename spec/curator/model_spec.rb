require "spec_helper"

describe Curator::Model do
  describe "initialize" do
    it "sets instance values provided in the args" do
      model_class = Class.new do
        include Curator::Model
        attr_reader :one, :two
      end

      model = model_class.new(:two => 't', :three => 'th')
      model.one.should be_nil
      model.two.should == 't'
    end

    it "does not set arbitrary fields" do
      model_class = Class.new do
        include Curator::Model
        attr_reader :foo
      end

      model = model_class.new(:foo => "bar", :baz => "qux")
      model.instance_variable_get("@baz").should be_nil
    end
  end

  describe "==" do
    it "is equals if ids match" do
      instance1 = TestModel.new(:id => "id")
      instance2 = TestModel.new(:id => "id")

      instance1.should == instance2
    end

    it "is not equals if ids don't match" do
      instance1 = TestModel.new(:id => "id")
      instance2 = TestModel.new(:id => "id2")

      instance1.should_not == instance2
    end
  end

  describe "touch" do
    it "updates the models timestamps to now" do
      model = TestModel.new
      model.created_at.should be_nil
      model.updated_at.should be_nil
      model.touch
      model.created_at.should_not be_nil
      model.updated_at.should_not be_nil
    end

    it "does not change created_at after it has been created" do
      model = TestModel.new
      model.touch
      created_at = model.created_at
      model.touch
      model.created_at.should == created_at
    end

    it "changes updated_at each time" do
      model = TestModel.new
      model.touch
      updated_at = model.updated_at
      model.touch
      model.updated_at.should_not == updated_at
    end

    it "saves times in utc" do
      model = TestModel.new
      model.touch
      model.updated_at.zone.should == "UTC"
      model.created_at.zone.should == "UTC"
    end
  end

  describe "version" do
    it "defaults to 0" do
      instance = TestModel.new
      instance.version.should == 0
    end

    it "can be set declaratively" do
      model_class = Class.new do
        include Curator::Model
        current_version 12
      end

      instance = model_class.new
      instance.version.should == 12
    end
  end

  describe "ActiveModel" do
    it "extends ActiveModel::Naming" do
      TestModel.model_name.should == "TestModel"
      eigenclass = class << TestModel; self; end
      eigenclass.ancestors.should include(ActiveModel::Naming)
    end

    it "includes ActiveModel::Conversion" do
      TestModel.new.to_param.should be_nil
      TestModel.new(:id => "foo").to_param.should == "foo"
      TestModel.ancestors.should include(ActiveModel::Conversion)
    end
  end
end
