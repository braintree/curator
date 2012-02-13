module Curator
  class Migration
    attr_accessor :version

    def initialize(version)
      @version = version
    end
  end
end
