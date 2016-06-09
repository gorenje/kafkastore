# encoding: UTF-8
require_relative '../test_helper'

class BatchWorkerTest < Minitest::Test

  def setup
  end

  context "basics" do
    should "work" do
      # This assumes tha Time.now won't change, so that klag = 0....
      ts  = Time.now.to_i
      str = "127.0.0.1 #{ts} clicks /t/click f=e&g=h iPhone Banana Phone"
      bw  = BatchWorker.new
      hsh = bw.send(:redis_string_to_kafka_hash, str)

      assert_equal({:meta=>{:ip=>2130706433, :ts=>ts.to_s,
                       :klag=>0, :country=>nil, :device=>"smartphone",
                       :platform=>"ios", :bot_name=>nil,
                       :device_name=>"iPhone"},
                     :topic=>"clicks",
                     :path=>"/t/click",
                     :params=>"f=e&g=h"}, hsh)
    end
  end
end
