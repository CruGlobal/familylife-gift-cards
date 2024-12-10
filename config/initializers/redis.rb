# frozen_string_literal: true

require "redis"

Redis.current = Redis.new(host: ENV.fetch("STORAGE_REDIS_HOST"),
  port: ENV.fetch("STORAGE_REDIS_PORT", 6379),
  db: ENV.fetch("STORAGE_REDIS_DB_INDEX", 3))
