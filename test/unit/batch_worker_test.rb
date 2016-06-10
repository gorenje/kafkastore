# encoding: UTF-8
require_relative '../test_helper'

class BatchWorkerTest < Minitest::Test

  def setup
    @queue = RedisQueue.new($redis_pool, :click_queue)
    @queue.clear!
  end

  context "converting redis strings" do
    should "handle missing user agent" do
      ts  = Time.now.to_i
      str = "127.0.0.1 #{ts} example /t/fubar p "
      bw  = BatchWorker.new
      hsh = bw.send(:redis_string_to_kafka_hash, str)

      assert_equal({:meta=>"bot_name&country&device&device_name&ip=2130706433"+
                     "&klag=0&platform=&ts=#{ts}",
                     :topic=>"example", :path=>"/t/fubar", :params=>"p"}, hsh)
    end

    should "work with correct data" do
      # This assumes tha Time.now won't change, so that klag = 0....
      ts  = Time.now.to_i
      str = "127.0.0.1 #{ts} clicks /t/click f=e&g=h iPhone Banana Phone"
      bw  = BatchWorker.new
      hsh = bw.send(:redis_string_to_kafka_hash, str)

      assert_equal({:meta=>"bot_name&country&device=smartphone&device_name="+
                     "iPhone&ip=2130706433&klag=0&platform=ios&ts=#{ts}",
                     :topic=>"clicks",
                     :path=>"/t/click",
                     :params=>"f=e&g=h"}, hsh)
    end
  end

  context "popping from queue" do
    should "call the inserter to push to kafka" do
      ts  = Time.now.to_i

      @queue.push(["127.0.0.1 #{ts} example /t/fubar p UserAgent"])
      mk = Object.new.tap do |o|
        mock(o).produce("/t/fubar bot_name&country&device&device_name&" +
                        "ip=2130706433&klag=0&platform=&ts=#{ts} p",
                        {:topic=>"example"})
        mock(o).deliver_messages
      end
      mock($kafka).producer { mk }

      bw = BatchWorker.new
      bw.perform(1)
    end
  end
end
