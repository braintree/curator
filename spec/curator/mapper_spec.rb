require 'spec_helper'

describe Curator::Mapper do
  describe "serialize" do
    it "serializes a field" do
      mapper = Curator::Mapper.new(:foo, :serialize => lambda { |v| v + 1 })
      mapper.serialize(:foo => 1).should == {:foo => 2}
    end

    it "ignores other fields" do
      mapper = Curator::Mapper.new(:foo, :serialize => lambda { |v| v + 1 })
      mapper.serialize(:bar => 1).should == {:bar => 1}
    end

    it "leaves fields alone if there is no option" do
      mapper = Curator::Mapper.new(:foo, {})
      mapper.serialize(:foo => 1).should == {:foo => 1}
    end
  end

  describe "deserialize" do
    it "deserializes a field" do
      mapper = Curator::Mapper.new(:foo, :deserialize => lambda { |v| v + 1 })
      mapper.deserialize(:foo => 1).should == {:foo => 2}
    end

    it "ignores other fields" do
      mapper = Curator::Mapper.new(:foo, :deserialize => lambda { |v| v + 1 })
      mapper.deserialize(:bar => 1).should == {:bar => 1}
    end

    it "leaves fields alone if there is no option" do
      mapper = Curator::Mapper.new(:foo, {})
      mapper.deserialize(:foo => 1).should == {:foo => 1}
    end
  end
end
