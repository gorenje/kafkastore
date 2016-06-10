class BatchInserter
  class Result < Struct.new(:invalid, :failed); end

  attr_reader :result, :raw_clicks

  def initialize(raw_clicks)
    @result     = Result.new([], [])
    @raw_clicks = raw_clicks
  end

  def do_insert
    begin
      producer = $kafka.producer

      with_connection do
        raw_clicks.map do |raw|
          producer.produce("%s %s %s" % [raw[:path], raw[:meta], raw[:params]],
                           :topic => raw[:topic])
        end

        measure(:batch_insert) do
          producer.deliver_messages
        end
      end
    rescue Timeout::Error => e
      $stderr.puts "db connection problem (batch): " + e.message
      result.failed += raw_clicks
    end

    report(raw_clicks.size, result.invalid.size, result.failed.size)
    result
  end

private

  def with_connection(timout = 60)
    Timeout::timeout(timout) do
      yield
    end
  end

  def measure(metric)
    $librato_aggregator.time("timing.#{metric}") do
      yield
    end
  end

  def report(total, invalid, failed)
    $librato_queue.add(
      "clicks"         => total - (invalid + failed),
      "clicks_invalid" => invalid,
      "clicks_failed"  => failed
    )
  end
end
