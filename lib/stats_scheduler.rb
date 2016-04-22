require 'sidekiq/api'

class StatsScheduler
  include Sidekiq::Worker

  def perform
    redis_queue         = RedisQueue.new($redis_pool, :click_queue)
    redis_invalid_queue = RedisQueue.new($redis_pool, :click_invalid)

    stats   = Sidekiq::Stats.new
    queue   = Sidekiq::Queue.new
    workers = Sidekiq::Workers.new
    redis   = redis_info

    return if ENV['LIBRATO_USER'].nil?

    $librato_queue.add(
      "click_queue_size"               => redis_queue.size,
      "click_invalid_queue_size"       => redis_invalid_queue.size,
      "sidekiq.processed"              => stats.processed,
      "sidekiq.failed"                 => stats.failed,
      "sidekiq.busy"                   => workers.size,
      "sidekiq.enqueued"               => stats.enqueued,
      "sidekiq.scheduled"              => stats.scheduled_size,
      "sidekiq.retries"                => stats.retry_size,
      "sidekiq.default_latency"        => queue.latency,
      "sidekiq.redis_used_memory"      => redis_info['used_memory'],
      "sidekiq.redis_used_memory_peak" => redis_info['used_memory_peak'],
      "sidekiq.redis_clients"          => redis_info['connected_clients']
    )
  end

private
  def redis_info
    info = Sidekiq.redis do |conn|
      conn.respond_to?(:namespace) ? conn.redis.info : conn.info
    end
    info.select { |k,_| k =~ /^(connected_clients|used_memory|used_memory_peak)$/ }
  end
end
