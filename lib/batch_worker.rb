class BatchWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :batch

  attr_reader :redis_queue

  DefaultCountry = OpenStruct.new(:iso_code => nil)

  def initialize
    @redis_queue = RedisQueue.new($redis_pool, :click_queue)
  end

  def perform(batch_size)
    click_hashes = redis_queue.pop(batch_size).map do |str|
      next if str.nil?
      redis_string_to_kafka_hash(str)
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

  def geoip_country(ip)
    ($geoip && ip && $geoip.lookup(ip).country) rescue DefaultCountry
  end

  def country_for_ip(ip)
    geoip_country(ip) || DefaultCountry
  end

  def store_invalid_clicks(clicks)
    invalid_queue.push(clicks)
  end

  def requeue_failed_clicks(clicks)
    redis_queue.push(clicks)
  end

  def invalid_queue
    @invalid_queue ||= RedisQueue.new($redis_pool, :click_invalid)
  end

  def redis_string_to_kafka_hash(str)
    splt = str.split
    dd   = DeviceDetector.new(splt[5..-1].join(" "))

    { :meta => {
        :ip          => IPAddr.new(splt[0]).to_i,
        :ts          => splt[1],
        :klag        => Time.now.to_i - splt[1].to_i,
        :country     => country_for_ip(splt[0]).iso_code,
        :device      => dd.device_type,
        :platform    => dd.os_name.to_s.downcase,
        :bot_name    => dd.bot_name,
        :device_name => dd.device_name
      },
      :topic   => splt[2],
      :path    => splt[3],
      :params  => splt[4],
    }
  end
end
