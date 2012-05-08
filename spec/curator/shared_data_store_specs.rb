shared_examples "data_store" do |data_store|
  describe "self.delete" do
    it "deletes an object by key" do
      data_store.save(:collection_name => "fake_things", :key => "some_key", :value => {"k" => "v"})
      data_store.find_by_key("fake_things", "some_key").should_not be_nil
      data_store.delete("fake_things", "some_key")
      data_store.find_by_key("fake_things", "some_key").should be_nil
    end
  end

  describe "self.find_by_index" do
    it "returns an empty array if key is not found" do
      data_store.find_by_index("abyss","invalid_index","invalid_key").should be_empty
    end

    it "returns an empty array if key is nil" do
      data_store.find_by_index("abyss","invalid_index", nil).should be_empty
    end

    it "returns multiple objects" do
      data_store.save(:collection_name => "test_collection", :key => "key1", :value => {:indexed_key => "indexed_value"}, :index => {:indexed_key => "indexed_value"})
      data_store.save(:collection_name => "test_collection", :key => "key2", :value => {:indexed_key => "indexed_value"}, :index => {:indexed_key => "indexed_value"})

      keys = data_store.find_by_index("test_collection", :indexed_key, "indexed_value").map { |data| data[:key] }
      keys.sort.should == ["key1", "key2"]
    end

    it "returns objects by key within a range" do
      data_store.save(:collection_name => "test_collection",  :key => "key1", :value => {:indexed_key => 'e'}, :index => {:indexed_key => 'e'})
      data_store.save(:collection_name => "test_collection",  :key => "key2", :value => {:indexed_key => 'g'}, :index => {:indexed_key => 'g'})

      data_store.find_by_index("test_collection", :indexed_key, ('a'..'f')).map { |data| data[:key] }.should == ["key1"]
      data_store.find_by_index("test_collection", :indexed_key, ('f'..'h')).map { |data| data[:key] }.should == ["key2"]
      data_store.find_by_index("test_collection", :indexed_key, ('a'..'h')).map { |data| data[:key] }.sort.should == ["key1", "key2"]
    end

    it "can find objects by index with a key containing a + character" do
      data_store.save(:collection_name => "test_collection", :key => "key1", :value => {:indexed_key => "indexed+value"}, :index => {:indexed_key => "indexed+value"})

      keys = data_store.find_by_index("test_collection", :indexed_key, "indexed+value").map { |data| data[:key] }
      keys.sort.should == ["key1"]
    end

    it "can find objects by index with an array index" do
      data_store.save(
        :collection_name => "test_collection",
        :key => "key1",
        :value => {:indexed_key => ["indexed_value1", "indexed_value2"]},
        :index => {:indexed_key => ["indexed_value1", "indexed_value2"]}
      )

      data_store.find_by_index("test_collection", :indexed_key, "indexed_value1").map { |data| data[:key] }.should == ["key1"]
      data_store.find_by_index("test_collection", :indexed_key, "indexed_value2").map { |data| data[:key] }.should == ["key1"]
      data_store.find_by_index("test_collection", :indexed_key, "indexed_value3").map { |data| data[:key] }.should == []
    end
  end

  describe "find_by_key" do
    it "returns nil when the key does not exist" do
      data_store.find_by_key("fake_things", "some_key_that_does_not_exist").should be_nil
    end

    it "returns an object by key" do
      data_store.save(:collection_name => "fake_things", :key => "some_key", :value => {"k" => "v"})
      data_store.find_by_key("fake_things", "some_key").should == {:key => "some_key", :data => {"k" => "v"}}
    end

    it "object key can contain a + character" do
      data_store.save(:collection_name => "fake_things", :key => "special+key", :value => {"k" => "v"})
      data_store.find_by_key("fake_things", "special+key").should == {:key => "special+key", :data => {"k" => "v"}}
    end
  end

  describe "self.save" do
    it 'generates a new key if not provided' do
      key1 = data_store.save(:collection_name => 'fake_things', :value => {:foo => 1})
      key2 = data_store.save(:collection_name => 'fake_things', :value => {:foo => 1})
      key1.should_not be_blank
      key2.should_not be_blank
      key1.should_not == key2
    end

    it 'returns the key' do
      key = data_store.save(:collection_name => 'fake_things', :key => 'abc', :value => {:foo => 1})
      key.should == 'abc'
    end

    it 'updates objects in place' do
      data_store.save(collection_name: 'fake_things', :key => 'foo', :value => {'foo' => 1})
      data_store.save(collection_name: 'fake_things', :key => 'foo', :value => {'foo' => 2})
      data_store.find_by_key('fake_things', 'foo').should == {:key => 'foo', :data => {'foo' => 2}}
    end

    it "can index by multiple things" do
      data_store.save(
        :collection_name => "fake_things",
        :key => "blah",
        :value => {:foo => "foo-data", :bar => "bar-data"},
        :index => {:foo => "foo-data", :bar => "bar-data"}
      )

      foo_result = data_store.find_by_index("fake_things", :foo, "foo-data").first
      foo_result[:key].should == "blah"

      bar_result = data_store.find_by_index("fake_things", :bar, "bar-data").first
      bar_result[:key].should == "blah"
    end
  end
end
