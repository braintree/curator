module Librarian
  class Railtie < Rails::Railtie
    initializer "railtie.configure_rails_initialization" do
      Librarian.environment = Rails.env
      Librarian.riak_config_file = Rails.root.join('config', 'riak.yml')
    end
  end
end
