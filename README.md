# Curator

See [Untangle Domain and Persistence Logic with Curator](http://www.braintreepayments.com/devblog/untangle-domain-and-persistence-logic-with-curator) for the announcement blog post.

Curator is a model and repository framework for Ruby. It's an alternative to ActiveRecord-like libraries where models are tightly coupled to persistence. Curator allows you to write domain object that are persistence free, and then write repositories that persist these objects. These ideas are largely taken from the [Repository](http://domaindrivendesign.org/node/123) section of [Domain Driven Design](http://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215).

Currently, curator supports [Riak](http://basho.com/products/riak-overview/), [MongoDB](http://www.mongodb.org/) and an in-memory data store for persistence. If you are interested in enhancing curator to support other data stores, please let us know.

## Usage

Domain objects should include the `Curator::Model` module:

```ruby
class Note
  include Curator::Model
  attr_accessor :id, :title, :description, :user_id
end
```

These models can be intiatiated with hashes and used just like regular ruby objects:

```ruby
note = Note.new(:title => "My Note", :description => "My description")
puts note.description
```

Repositories should include the `Curator::Repository` module:

```ruby
class NoteRepository
  include Curator::Repository
  indexed_fields :user_id
end
```

Repositories have `save`, `find_by_id`, and `find_by` and `find_first_by` methods for indexed fields. `find_by` methods return an array of all matching records, while `find_first_by` only returns the first match (with no ordering):

```ruby
note = Note.new(:user_id => "my_user")
NoteRepository.save(note)

note1 = NoteRepository.find_by_id(note.id)
note2 = NoteRepository.find_first_by_user_id("my_user")
my_notes = NoteRepository.find_by_user_id("my_user")
```

Fields included in indexed_fields automatically get a secondary index when persisted to Riak.

### Rails

See [curator_rails_example](/braintree/curator_rails_example) for an example application using curator.

If you use curator within Rails, all you need is to add curator to your Gemfile and create a config/riak.yml with contents like:

```yaml
development:
  :http_port: 8098
  :host: localhost
test:
  :http_port: 8098
  :host: localhost
```

We recommend putting your models in app/models and your repositories in app/repositories. If you do this, don't forget to add app/repositories to the list of autoload paths:

```ruby
# config/application.rb

config.autoload_paths += %W(#{config.root}/app/repositories)
```

You can also use Rails form builder with curator models:

```erb
<%= form_for @note, :url => { :action => "create" } do |f| %>
  <dl>
    <dt><%= f.label :title %></dt>
    <dd><%= f.text_field :title %></dd>
    <dt><%= f.label :description %></dt>
    <dd><%= f.text_area :description, :size => "60x12" %></dd>
  </dl>
  <%= f.submit "Create" %>
```

### Without Rails

If you are not using Rails, you can configure curator manually:

```ruby
Curator.configure(:riak) do |config|
  config.bucket_prefix = "my_app"
  config.environment = "development"
  config.migrations_path = File.expand_path(File.dirname(__FILE__) + "/../db/migrate")
  config.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/config/riak.yml")
end
```

## Testing

If you are writing tests using curator, it's likely that you will want a way to clean up your data in Riak between tests. Riak does not provide an easy way to clear out all data, so curator takes care of it for you. You can use the following methods if you change your backend from `:riak` to `:resettable_riak`:

- `remove_all_keys` - remove everything in Riak under the current bucket_prefix and environment
- `reset!` - remove all keys since the last reset!

For example, our `spec_helper.rb` file looks like this for our [rspec](https://www.relishapp.com/rspec) test suite:

```ruby
Curator.configure(:resettable_riak) do |config|
  config.bucket_prefix = "curator"
  config.environment = "test"
  config.migrations_path = File.expand_path(File.dirname(__FILE__) + "/../db/migrate")
  config.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
end

RSpec.configure do |config|
  config.before(:suite) do
    Curator.data_store.remove_all_keys
  end

  config.after(:each) do
    Curator.data_store.reset!
  end
end
```

This ensures that our tests start with an empty Riak, and the data gets removed in between tests.

## Data Migrations

See [Data migrations for NoSQL with Curator](http://www.braintreepayments.com/devblog/data-migrations-for-nosql-with-curator) for an overview of data migrations. They have also been implemented in the [curator_rails_example](/braintree/curator_rails_example).

Each model instance has an associated version that is persisted along with the object. By default, all instances start at version 0. You can change the default by specifying the `current_version` in the model class:

```ruby
class Note
  current_version 1
end

note = Note.new
note.version #=> 1
```

When the repository reads from the data store, it compares the stored version number to all available migrations for that collection. If any migrations are found with a higher version number, the attributes for the instance are run through each migration in turn and then used to instantiate the object. This means that migrations are lazy, and objects will get migrated as they are used, rather than requiring downtime while all migrations run.

In order to write a migration, create a folder with the collection name under the `migrations_path` that was configured in the `Curator.configure` block.

```bash
mkdir db/migrate/notes/
```
Then, create a file with a filename that matches `#{version}_#{class_name}.rb`:

```ruby
# db/migrate/notes/0001_update_description.rb

class UpdateDescription < Curator::Migration
  def migrate(attributes)
    attributes.merge(:description => attributes[:description].to_s + " -- Passed through migration 1")
  end
end
```

Now, all Note objects that are read with a version lower than 1 will have their description ammended. Migrations are free to do what they want with the attributes. They can add, edit or delete attributes in any combination desired. All that matters is that the resulting attributes hash will be used to instantiate the model.

Since migrations merely accept and return a hash, they are easy to unit test. They do not affect the data store directly (like `ActiveRecord` migrations), so there is no harm in calling them in tests:

```ruby
require 'spec_helper'
require 'db/migrate/notes/0001_update_description'

describe UpdateDescription do
  describe "migrate" do
    it "appends to the description" do
      attributes = {:description => "blah"}
      UpdateDescription.new(1).migrate(attributes)[:description].should == "blah -- Passed through migration 1
    end
  end
end
```

## Under the hood

Curator stores objects in the data store using the id as the key. The value is a json representation of the instance_values of the object. Your repository can implement serialize/deserialize to get different behavior.

### Riak

The bucket name in Riak is `<bucket_prefix>:<environment>:<collection>`. The bucket prefix is configurable. By default, it will either be `curator` or the name of the Rails application if you are using curator within Rails. The collection is derived from the name of the Repository class, and it can be overriden. For example, if you implement a NoteRepository, the riak bucket will be `curator:development:notes` in development mode, and `curator:production:notes` in production mode.

### MongoDB

The collection name in MongoDB is derived from the name of the Repository class, and it can be overriden. For example, if you implement a NoteRepository, the collection name will be `notes`.

MongoDB will preserve the types of attributes. For example, if you set an attribute as a `Time` object, it will come back as a `Time` object. If you do not set a key for an object, MongoDB will generate one as a `BSON::ObjectId`, which will be returned. If you want to `find_by_id`, you will have to use the `BSON::ObjectId` class, not a `String`. On the other hand, if you specify keys as strings, you can look them back up as strings.

## Contributing

We appreciate contributions of any kind. If you have code to show us, open a pull request. If you found a bug, want a new feature, or just want to talk design before submitting a pull request, open an issue.

Please include tests with code contributions, and try to follow conventions that you find in the code.

Riak is required in order to run the curator specs. After installing Riak, change the backend to eleveldb. For example, here is how to install on OS X using [homebrew](http://mxcl.github.com/homebrew/):

```bash
brew install riak
edit /usr/local/Cellar/riak/<riak version>/libexec/etc/app.config

  change
    {storage_backend, riak_kv_bitcask_backend},
  to
    {storage_backend, riak_kv_eleveldb_backend},

ulimit -n 1024
riak start
```


### Writing new data stores

Curator has a set of shared_examples for data store specs. Take a look at `spec/curator/shared_data_store_specs.rb`. These cover most of the data store functionality, so include these on your spec and make them pass:

```ruby
require 'spec_helper'
require 'curator/shared_data_store_specs'

module Curator::SomeNewDB
  describe Curator::SomeNewDB::DataStore do
    include_examples "data_store", DataStore

    ... other specs specific to SomeNewDB ...
  end
end
```

## License

Curator is released under the [MIT license](http://www.opensource.org/licenses/MIT).
