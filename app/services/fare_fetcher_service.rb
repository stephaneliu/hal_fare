# Class obtains fares from website for persistence
class FareFetcherService
  attr_reader :cities, :connection, :destination,
              :logger, :months, :origin, :routes, :parser

  def initialize(connection, parser, routes, logger = Logger.new(STDOUT),
                 months = [1.day.from_now.localtime,
                           1.month.from_now, 2.months.from_now,
                           3.months.from_now, 4.months.from_now])
    @connection = connection
    @parser     = parser
    @months     = months
    @routes     = routes
    @logger     = logger
  end

  def fares
    routes.each do |origin, destination|
      @origin      = origin
      @destination = destination

      obtain_fare
      update_low_fare_cache
    end
  end

  private

  def obtain_fare
    months.each do |month|
      content      = connection.get_content(origin.code, destination.code,
                                            month)
      parser.month = month

      parser.parse(content).each do |day, content_fare|
        Fare.new(price: content_fare, departure_date: day,
                 origin: origin, destination: destination).smart_save
      end
    end
  end

  def update_low_fare_cache
    LowFareStatistic.new(origin, destination).create_low_fare
  end
end
