def new_redis
  Redis.new(url: ENV['REDIS_URL'])
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 5) { new_redis }
end

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 5) { new_redis }
end

if ENV['RAILS_ENV'] == 'test'
  require 'sidekiq/testing'
  puts "\n DEBUG: test environment, sidekiq is running inline"
  Sidekiq::Testing.inline!
end
