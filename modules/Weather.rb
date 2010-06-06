
#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

require "uri"
require 'net/http'
require 'rexml/document'

def initialize
  $bot.modHelp.registerModule("Weather", "Weather information look-ups with persistent location memory.")

  $bot.modHelp.registerCommand("Weather", "weather-default", "Set or delete your default weather location. If delete is specified, any default will be removed. if location is specified, your user@host will be associated with that location.", "[delete] [location]")
  $bot.modHelp.registerCommand("Weather", "weather", "View current conditions for the specified location. If none is specified, your default location is used. If no default is set and a location is specified, save the new location as your default.", "[location]")
  $bot.modHelp.registerCommand("Weather", "forecast", "View a short-term forecase for the specified location. If none is specified, your default location is used. If no default is set and a location is specified, save the new location as your default.", "[location]")
end


def getDefault(message)
  user = message.speaker.partialMask

  config = $bot.modConfig.get("weather", user)

  if config == nil
    if message.args.empty?
      return nil
    else
      $bot.modConfig.put("weather", user, message.args)
      reply(message, "I have set your default location to #{message.args}. To change this, use the command #{BOLD}WEATHER-DEFAULT#{NORMAL}")
      return message.args
    end
  else
    return message.args unless message.args.empty?
    return config
  end
end

def cmd_weather_default(message)
  user = message.speaker.partialMask

  if message.args.empty?
    $bot.modConfig.delete("weather", user)

    reply(message, "I have deleted your default weather location. If you want to set a new one, use the command #{BOLD}WEATHER-DEFAULT#{NORMAL} or just use any weather-related commands.")
  else
    $bot.modConfig.put("weather", user, message.args)

    reply(message, "I have set your default location to #{message.args}. You can change it at any time using the same command. To remove it, don't give a location.")
  end

end

def cmd_weather(message)
  location = getDefault(message)

  if location == nil
    reply(message, "You do not have a default location, and so you must provide one.")
    return
  end

  url = "http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=#{URI.escape(location)}"

  body = Net::HTTP.get URI.parse(url)
  root = (REXML::Document.new(body)).root

  weather = root.elements["//weather"].text rescue nil

  if weather == nil
    reply(message, "That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.")
    return
  end

  credit = root.elements["//credit"].text
  updatedTime = root.elements["//observation_epoch"].text.to_i
  localTime = root.elements["//local_time"].text
  stationLocation = root.elements["//observation_location/full"].text
  temperature = root.elements["//temperature_string"].text
  humidity = root.elements["//relative_humidity"].text
  wind = root.elements["//wind_string"].text
  pressure = root.elements["//pressure_string"].text
  dewpoint = root.elements["//dewpoint_string"].text
  link = root.elements["//forecast_url"].text

  updatedTime = "Updated #{Time.now.utc.to_i - updatedTime} seconds ago"

  reply = "[#{BOLD}#{credit}#{NORMAL} for #{BOLD}#{stationLocation}#{NORMAL}] "
  reply += "Current Conditions: #{COLOR}07#{weather}#{NORMAL}; "
  reply += "Temperature: #{COLOR}07#{temperature}#{NORMAL}; "
  reply += "Humidity: #{COLOR}07#{humidity}#{NORMAL}; "
  reply += "Wind: #{COLOR}07#{wind}#{NORMAL}; "
  reply += "Pressure: #{COLOR}07#{pressure}#{NORMAL}; "
  reply += "Dewpoint: #{COLOR}07#{dewpoint}#{NORMAL}; "
  reply += "#{updatedTime} (local time: #{COLOR}07#{localTime}#{NORMAL}); "
  reply += "#{link}"

  reply(message, reply)
end


def cmd_forecast(message)
  location = getDefault(message)

  if location == nil
    reply(message, "You do not have a default location, and so you must provide one.")
    return
  end
  url = "http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=#{URI.escape(location)}"

  body = Net::HTTP.get URI.parse(url)
  root = (REXML::Document.new(body)).root.elements["//txt_forecast"]

  date = root.elements["date"].text rescue nil

  if date == nil
    reply(message, "That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.")
    return
  end

  reply = "[#{BOLD}Forecast for #{message.args}#{NORMAL} as of #{BOLD}#{date}#{NORMAL}] "

  root.elements.each("forecastday") { |element|
    title = element.elements["title"].text
    text = element.elements["fcttext"].text
    reply += "[#{BOLD}#{title}#{NORMAL}] #{text}] "
  }

  reply(message, reply)
end
