class BatchWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :batch

  attr_reader :redis_queue

  def initialize
    @redis_queue = RedisQueue.new($redis_pool, :click_queue)
  end

  def perform(batch_size)
    click_hashes = redis_queue.pop(batch_size).map do |hsh|
      a = hsh["attribution_window"].split("..")
      hsh.merge("attribution_window" =>
                (DateTime.parse(a.first)..DateTime.parse(a.last)))
    end

    unless click_hashes.empty?
      inserter = BatchInserter.new(click_hashes)
      result   = inserter.do_insert

      store_invalid_clicks(result.invalid) unless result.invalid.empty?

      requeue_failed_clicks(result.failed) unless result.failed.empty?
    end
  end

private

  def store_invalid_clicks(clicks)
    invalid_queue.push(clicks)
  end

  def requeue_failed_clicks(clicks)
    redis_queue.push(clicks)
  end

  def invalid_queue
    @invalid_queue ||= RedisQueue.new($redis_pool, :click_invalid)
  end
end
