require 'json'

class RedisQueue
  attr_reader :connection_pool, :key

  def initialize(connection_pool, key)
    @connection_pool = connection_pool
    @key             = key
  end

  def push(elements)
    elements = elements.map do |element|
      encode(element)
    end

    with_redis do |redis|
      redis.pipelined do |pipe|
        elements.each {|e| pipe.rpush(key, e)}
      end
    end
  end

  def pop(number_of_elements = 20)
    elements = with_redis do |redis|
      redis.pipelined do |pipe|
        number_of_elements.times { pipe.lpop(key) }
      end
    end

    elements.compact.map do |element|
      decode(element)
    end
  end

  def peek_all
    with_redis { |redis| redis.lrange(key, 0, redis.llen(key)) }.map do |e|
      decode(e)
    end
  end

  def size
    with_redis {|redis| redis.llen(key)}
  end

  def clear!
    with_redis {|redis| redis.del(key)}
  end

  protected

  def encode(element)
    JSON.dump(element)
  end

  def decode(element)
    JSON.parse(element)
  end

  def with_redis
    connection_pool.with do |redis|
      yield redis
    end
  end
end
