# Class gets fares from external site given origin and destination
# airport code of origin and destination on new
class FareConnectionService
  attr_reader :mechanize, :origin, :destination, :departure_date, :travelers

  def initialize(origin, destination,
                 departure_date = 1.day.from_now.to_date, travelers = 4)
    @mechanize      = Mechanize.new
    @origin         = origin.upcase
    @destination    = destination.upcase
    @departure_date = departure_date.strftime('%m/%d/%y')
    @travelers      = travelers
  end

  def get_content(outbound = true)
    agent = create_secure_agent

    Nokogiri::HTML.parse agent.get(calendar_url(outbound)).content
  end

  private

  def create_secure_agent
    mechanize.tap { |mech| mech.ssl_version = 'SSLv3' }
  end

  # rubocop:disable all
  def calendar_url(outbound = true)
    # origin must be uppercase - very picky
    "https://fly.hawaiianairlines.com/Calendar/Calendar.aspx" +
      "?orig=#{origin}" +
      "&dest=#{destination}" +
      "&traveler=#{travelers}" +
      "&depDate=#{departure_date}" +
      "&owORob=#{outbound}" +
      "&isDM=false" +
      "&isRoundTrip=true" +
      "&isEAward=false"
  end
end
