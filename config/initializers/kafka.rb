require 'kafka'

logger = Logger.new($stderr)
$kafka = Kafka.new(:seed_brokers => ["#{ENV['KAFKA_HOST']}:9092"],
                   :logger => logger)
