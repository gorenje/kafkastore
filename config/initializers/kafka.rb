require 'kafka'
require_relative './host_handler'

logger = Logger.new($stderr)
$kafka = Kafka.new(:seed_brokers => ["#{$hosthandler.kafka.host}:9092"],
                   :logger => logger)
