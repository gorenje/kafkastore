class BatchWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :batch

  attr_reader :redis_queue

  DefaultCountry = OpenStruct.new(:iso_code => "NOCO")

  def initialize
    @redis_queue = RedisQueue.new($redis_pool, :click_queue)
  end

  def geoip_country(ip)
    ($geoip && ip && $geoip.lookup(ip).country) rescue DefaultCountry
  end

  def country_for_ip(ip)
    geoip_country(ip) || DefaultCountry
  end

  def perform(batch_size)
    click_hashes = redis_queue.pop(batch_size).map do |str|
      next if str.nil?

      splt = str.split
      { :raw     => (splt[0..1] + splt[3..4]).join(" "),
        :topic   => splt[2],
        :country => country_for_ip(splt[0]).iso_code || "NOCO",
        :device  => DeviceDetector.new(splt[5..-1].join(" ")).device_type
      }
    end.compact

    unless click_hashes.empty?
      inserter = BatchInserter.new(click_hashes)
      result   = inserter.do_insert

      store_invalid_clicks(result.invalid) unless result.invalid.empty?

      requeue_failed_clicks(result.failed) unless result.failed.empty?
    end
  rescue Exception => e
    puts e.message
    puts e.backtrace
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
