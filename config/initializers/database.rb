require 'yaml'
require 'active_record'
require 'activerecord-import'

Dir[File.join(File.dirname(__FILE__),'..','..','models','*.rb')].each do |f|
  require f
end

# to generate an initial .env, don't need a database
if ENV['DATABASE_URL']
  ActiveSupport.on_load(:active_record) do
    env = ENV['RACK_ENV']
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.logger = env == 'development' ? Logger.new(STDOUT) : nil
    puts "DB connection established for #{env}"
  end
end
