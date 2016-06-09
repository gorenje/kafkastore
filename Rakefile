ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler'
require 'bundler/setup'

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

require 'rake'
require 'yaml'

task :environment do
  require_relative 'application'
end

begin
  task :default => :test
  require 'rake/testtask'
  Rake::TestTask.new(:test) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue Exception => e
  # Bundler not installed on the server.
end

Dir[File.join(File.dirname(__FILE__), 'lib', 'tasks','*.rake')].
  each { |f| load f }
