
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#

require "uri"
require 'net/http'
require 'rexml/document'
require 'htmlentities'

def initialize
  register_script("Weather information look-ups via Weather Underground (wunderground.com).")

  register_command("weather",   :weather,  1,  0, "View current conditions for the specified location.")
  register_command("temp",      :temp,     1,  0, "View current temperature for the specified location.")
  register_command("forecast",  :forecast, 1,  0, "View a short-term forecast for the specified location.")
end

def weather(msg, params)
  url = "http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=#{URI.escape(params.join)}"

  body = Net::HTTP.get URI.parse(url)
  root = (REXML::Document.new(body)).root

  weather = root.elements["//weather"].text rescue nil

  if weather == nil
    msg.reply("That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.")
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

  updatedTime = "Updated #{Time.at(updatedTime).to_duration_s} ago"

  reply = "[\02#{credit}\02 for \02#{stationLocation}\02] "
  reply << "Currently: \02#{weather}\02; "
  reply << "Temp: \02#{temperature}\02; "
  reply << "Humidity: \02#{humidity}\02; "
  reply << "Wind: \02#{wind}\02; "
  reply << "Pressure: \02#{pressure}\02; "
  #reply << "Dewpoint: \02#{dewpoint}\02; "
  reply << "#{updatedTime}; "
  reply << "#{link}"

  msg.reply(reply)
end

def temp(msg, params)
  url = "http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=#{URI.escape(params.join)}"

  body = Net::HTTP.get URI.parse(url)
  root = (REXML::Document.new(body)).root

  weather = root.elements["//weather"].text rescue nil

  if weather == nil
    msg.reply("That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.")
    return
  end

  credit = root.elements["//credit"].text
  stationLocation = root.elements["//observation_location/full"].text
  temperature = root.elements["//temperature_string"].text

  reply = "[\02#{credit}\02 for \02#{stationLocation}\02] "
  reply << "Temperature: \02#{temperature}\02"

  msg.reply(reply)
end

def forecast(msg, params)
  url = "http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=#{URI.escape(params[0])}"

  body = Net::HTTP.get URI.parse(url)
  root = (REXML::Document.new(body)).root.elements["//txt_forecast"]

  date = root.elements["date"].text rescue nil

  if date == nil
    msg.reply("That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.")
    return
  end

  reply = "[\02Forecast for #{params[0]}\02 as of \02#{date}\02] "

  root.elements.each("forecastday") { |element|
    title = element.elements["title"].text

    text = element.elements["fcttext"].text
    text = HTMLEntities.new.decode(text)

    reply << "[\02#{title}\02] #{text} "
  }

  msg.reply(reply)
end
