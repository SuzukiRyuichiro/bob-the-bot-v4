# frozen_string_literal: true

require 'geocoder'
require 'date'
require 'json'
require 'open-uri'

def fetch_weather(message)
  # Check if the API key is set
  api_key = ENV['WEATHER_API']
  return "Sorry, you haven't setup Open weather API token yet" unless api_key

  # Accepted message:
  # ~~~~~ weather in XXXXX
  #  ^anything          ^will become the location
  location = message.match(/.*eather in (\w+).*/)[1]

  # Coordinates from keyword
  coord = Geocoder.search(location).first.coordinates
  url = "https://api.openweathermap.org/data/3.0/onecall?lat=#{coord[0]}&lon=#{coord[1]}&exclude=current,minutely,hourly&appid=#{api_key}"

  begin
    data_serialized = URI.open(url).read
  rescue OpenURI::HTTPError => e
    return 'No weather forecast for this city...'
  end

  data = JSON.parse(data_serialized)['daily'][0..3]

  days = ['today', 'tomorrow', (Date.today + 2).strftime('%A'), (Date.today + 3).strftime('%A')]
  weather_forcast = data.map.with_index do |day, index|
    [days[index], day['weather'][0]['main'], day['temp']['day'] - 272.15]
  end
  freq = weather_forcast.map { |day| day[1] }.each_with_object(Hash.new(0)) do |v, h|
    h[v] += 1
  end
  most_freq_weather = freq.max_by { |_k, v| v }[0]

  # Report creation
  report = "The weather is mostly #{most_freq_weather.upcase} in #{location} for the next 4 days.\n"
  # If there are particular weather days
  other_weathers = weather_forcast.reject { |day| day[1] == most_freq_weather }
  report += "Except on #{other_weathers.map { |day| "#{day[0]}(#{day[1]})" }.join(', ')}.\n" if other_weathers.any?
  # tempreatures
  report += "\nThe temperature will be:\n#{weather_forcast.map { |day| " #{day[2].round}˚C for #{day[0]}" }.join("\n")}"
  # Return the string from fore_cast data
  report
end
