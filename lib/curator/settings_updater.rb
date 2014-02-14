module Curator
  class SettingsUpdater
    attr_reader :repositories
    attr_accessor :counter

    def initialize(repositories = Curator.repositories, options = {})
      @repositories = repositories
      @verbose = options.fetch(:verbose, true)
      @logger = options.fetch(:logger, STDOUT)
      @counter = 0
    end

    def run!
      announce "Preparing to apply settings to all repositories..."
      repositories.each do |repository|
        next unless repository.settings_uncommitted?
        announce " * Updating settings for #{repository}...", :finish => false,
                                                              :header => false
        if repository.apply_settings!
          finish
        else
          finish "Failed."
        end
        self.counter += 1
      end
      complete!
    end

  private
    attr_reader :logger

    def complete!
      if any_run?
        announce "Done!"
      else
        announce "Nothing to do."
      end
    end

    def announce(msg, options = {})
      return unless verbose?
      finish = options.fetch(:finish, true)
      header = options.fetch(:header, true)
      logger.write "[Curator] " if header
      logger.write msg
      logger.write "\n" if finish
    end

    def finish(msg = "Done!")
      return unless verbose?
      logger.write " #{msg}\n"
    end

    def verbose?
      @verbose
    end

    def any_run?
      counter > 0
    end
  end
end
