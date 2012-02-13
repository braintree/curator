#!/usr/bin/env rake

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :gem do
  desc "clean generated gems"
  task :clean do
    rm_f Dir.glob("*.gem")
  end

  desc "build the gem"
  task :build => :clean do
    sh "gem build curator.gemspec"
  end

  desc "push the gem"
  task :push => :build do
    sh "gem push #{Dir.glob("*.gem").first}"
  end
end
