require "spec_helper"

describe Librarian::Model do
  describe "self.included" do
    it "adds accessors for created_at and updated_at" do
      instance = TestModel.new
      instance.created_at = :created_at
      instance.updated_at = :updated_at

      instance.created_at.should == :created_at
      instance.updated_at.should == :updated_at
    end
  end

  describe "==" do
    it "is equals if ids match" do
      instance1 = TestModel.new
      instance1.id = "id"
      instance2 = TestModel.new
      instance2.id = "id"

      instance1.should == instance2
    end

    it "is not equals if ids don't match" do
      instance1 = TestModel.new
      instance1.id = "id"
      instance2 = TestModel.new
      instance2.id = "id2"

      instance1.should_not == instance2
    end
  end

  describe "version" do
    it "defaults to 0" do
      instance = TestModel.new
      instance.version.should == 0
    end

    it "can be set declaratively" do
      model_class = Class.new do
        include Librarian::Model
        current_version 12
      end

      instance = model_class.new
      instance.version.should == 12
    end
  end
end
