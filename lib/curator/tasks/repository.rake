require 'curator/settings_updater'

namespace :curator do
  namespace :repository do
    desc 'Apply settings to all repositories'
    task :apply => :environment do
      repositories = Dir[File.join(Rails.root,'app/repositories/**/*.rb')]
      repositories.each { |r| require r }

      Curator::SettingsUpdater.new.run!
    end
  end
end
