# Class obtains fares from website for persistence
class FareFetcherService
  attr_reader :cities, :connection, :destination,
              :logger, :months, :origin, :routes, :parser

  def initialize(connection, parser, routes,
                 months = [1.day.from_now.localtime,
                           1.month.from_now, 2.months.from_now,
                           3.months.from_now, 4.months.from_now])
    @connection = connection
    @parser     = parser
    @months     = months
    @routes     = routes
  end

  def fares
    routes.each_with_object([]) do |route, fares|
      @origin, @destination = route

      obtain_fare do |fare|
        fare.smart_save
        fares << fare
      end

      update_low_fare_cache
    end
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def obtain_fare
    start_time = Time.now

    months.each do |month|
      content               = connection.get_content(origin.code, destination.code, month)
      parser.departure_date = month

      parser.parse(content).each do |day, content_fare|
        yield Fare.new(price: content_fare, departure_date: day,
                       origin: origin, destination: destination)
      end
    end

    Rails.logger.info(
      "#{Time.now.to_s(:db)} - Obtaining fare for #{origin.code}/#{destination.code} \
(elapsed: #{Time.now - start_time})")
  end

  def update_low_fare_cache
    start_time = Time.now

    LowFareStatistic.new(origin, destination).create_low_fare

    end_time = Time.now
    Rails.logger.info("#{end_time.to_s(:db)} - Caching low fare for \
#{origin.code}/#{destination.code} (elapsed: #{end_time - start_time})")
  end
end