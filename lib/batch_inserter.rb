require 'pg'

class BatchInserter
  DB_CONNECTION_ERRORS = [
    PG::Error
  ]

  class Result < Struct.new(:invalid, :failed); end

  attr_reader :result, :raw_clicks

  def initialize(raw_clicks)
    @result     = Result.new([], [])
    @raw_clicks = raw_clicks
  end

  def do_insert
    begin
      with_connection do
        clicks = raw_clicks.map do |raw|
          Click.new(raw)
        end

        measure(:batch_insert) do
          Click.import(Click.columns.map(&:name)-["id"], clicks,
                       :timestamps => false)
        end
      end
    rescue ActiveRecord::StatementInvalid => e
      do_single_inserts
    rescue Timeout::Error, *DB_CONNECTION_ERRORS => e
      $stderr.puts "db connection problem (batch): " + e.message
      result.failed += raw_clicks
    end

    report(raw_clicks.size, result.invalid.size, result.failed.size)
    result
  end

private

  def do_single_inserts
    raw_clicks.each do |raw|
      begin
        with_connection(10) do
          measure(:single_insert) do
            Click.create(raw)
          end
        end
      rescue ActiveRecord::StatementInvalid => e
        $stderr.puts e.message
        result.invalid << raw
      rescue Timeout::Error, *DB_CONNECTION_ERRORS => e
        $stderr.puts "db connection problem (single): " + e.message
        result.failed << raw
      end
    end
  end

  def with_connection(timout = 60)
    Timeout::timeout(timout) do
      ActiveRecord::Base.connection_pool.with_connection do
        yield
      end
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
