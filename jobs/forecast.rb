require 'net/https'
require 'json'

# Forecast API Key from https://developer.forecast.io
forecast_api_key = "fdeb9ad7c0bd05e6903adbb831ac7758"

# Latitude, Longitude for location
forecast_location_lat = "38.8951118000"
forecast_location_long = "-77.0363658000"

# Unit Format
# "us" - U.S. Imperial
# "si" - International System of Units
# "uk" - SI w. windSpeed in mph
forecast_units = "us"
  
SCHEDULER.every '5m', :first_in => 0 do |job|
  http = Net::HTTP.new("api.forecast.io", 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  response = http.request(Net::HTTP::Get.new("/forecast/#{forecast_api_key}/#{forecast_location_lat},#{forecast_location_long}?units=#{forecast_units}"))
  forecast = JSON.parse(response.body)
  forecast_current_temp = forecast["currently"]["temperature"].round
  forecast_current_humidity = forecast["currently"]["humidity"] * 100
  forecast_current_humidity = forecast_current_humidity.round
  forecast_feels_like = forecast["currently"]["apparentTemperature"].round
  forecast_daily_low = forecast["daily"]["data"][0]["temperatureMin"].round
  forecast_daily_high = forecast["daily"]["data"][0]["temperatureMax"].round
  forecast_current_icon = forecast["currently"]["icon"]
  forecast_current_desc = forecast["currently"]["summary"]
  if forecast["minutely"]  # sometimes this is missing from the response.  I don't know why
    forecast_next_desc  = forecast["minutely"]["summary"]
    forecast_next_icon  = forecast["minutely"]["icon"]
  else
    puts "Did not get minutely forecast data again"
    forecast_next_desc  = "No data"
    forecast_next_icon  = ""
  end
  forecast_later_desc   = forecast["hourly"]["summary"]
  forecast_later_icon   = forecast["hourly"]["icon"]
  send_event('forecast', { current_temp: "#{forecast_current_temp}&deg;",
                           feels_like: "#{forecast_feels_like}&deg;",
                           current_humidity: "#{forecast_current_humidity}%",
                           current_icon: "#{forecast_current_icon}",
                           current_desc: "#{forecast_current_desc}",
                           next_icon: "#{forecast_next_icon}",
                           next_desc: "#{forecast_next_desc}",
                           later_icon: "#{forecast_later_icon}",
                           later_desc: "#{forecast_later_desc}",
                           daily_high: "#{forecast_daily_high}&deg;",
                           daily_low: "#{forecast_daily_low}&deg;"
                         }
             )
end
