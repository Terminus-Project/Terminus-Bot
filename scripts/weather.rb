#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

require 'rexml/document'
require 'htmlentities'

raise "weather script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Weather information look-ups via Weather Underground (wunderground.com).'


command 'weather', 'View current conditions for the specified location.' do
  argc! 1

  url = "http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=#{URI.escape(@params.join ' ')}"

  Bot.http_get(URI(url)) do |response|

    unless response.status == 200
      riase 'There was a problem performing the looking up the weather for that location. Please try again later.'
    end

    root = (REXML::Document.new(response.content)).root

    weather = root.elements["//weather"].text rescue nil

    if weather == nil
      output "That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way."
      next
    end

    credit          = root.elements["//credit"].text
    updatedTime     = root.elements["//observation_epoch"].text.to_i
    localTime       = root.elements["//local_time"].text
    stationLocation = root.elements["//observation_location/full"].text
    temperature     = root.elements["//temperature_string"].text
    humidity        = root.elements["//relative_humidity"].text
    wind            = root.elements["//wind_string"].text
    pressure        = root.elements["//pressure_string"].text
    dewpoint        = root.elements["//dewpoint_string"].text
    link            = root.elements["//forecast_url"].text

    updatedTime = "Updated #{Time.at(updatedTime).to_fuzzy_duration_s} ago"

    output =  "[\02#{credit}\02 for \02#{stationLocation}\02] "
    output << "Currently: \02#{weather}\02; "
    output << "Temp: \02#{temperature}\02; "
    output << "Humidity: \02#{humidity}\02; "
    output << "Wind: \02#{wind}\02; "
    output << "Pressure: \02#{pressure}\02; "
    #output << "Dewpoint: \02#{dewpoint}\02; "
    output << "#{updatedTime}; "
    output << "#{link}"

    reply output

  end
end

command 'temp', 'View current temperature for the specified location.' do
  argc! 1

  url = "http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=#{URI.escape(@params.join ' ')}"

  Bot.http_get(URI(url)) do |response|

    unless response.status == 200
      raise 'There was a problem performing the looking up the weather for that location. Please try again later.'
    end

    root = (REXML::Document.new(response.content)).root

    weather = root.elements["//weather"].text rescue nil

    if weather == nil
      raise 'That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.'
    end

    credit          = root.elements["//credit"].text
    stationLocation = root.elements["//observation_location/full"].text
    temperature     = root.elements["//temperature_string"].text

    output =  "[\02#{credit}\02 for \02#{stationLocation}\02] "
    output << "Temperature: \02#{temperature}\02"

    reply output
  end
end

command 'forecast', 'View a short-term forecast for the specified location.' do
  argc! 1

  url = "http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=#{URI.escape(@params.join ' ')}"

  Bot.http_get(URI(url)) do |response|

    unless response.status == 200
      raise 'There was a problem performing the looking up the weather for that location. Please try again later.'
    end

    root = (REXML::Document.new(response.content)).root.elements["//txt_forecast"]

    date = root.elements["date"].text rescue nil

    if date == nil
      raise 'That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.'
    end

    output = "[\02Forecast for #{@params.join ' '}\02 as of \02#{date}\02] "

    count = 0

    root.elements.each("forecastday") do |element|
      title = element.elements["title"].text

      text = element.elements["fcttext"].text
      text = HTMLEntities.new.decode(text)

      output << "[\02#{title}\02] #{text} "

      count += 1
      break if count == 2
    end

    if count == 0
      raise 'That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.'
    end

    reply output
  end
end

