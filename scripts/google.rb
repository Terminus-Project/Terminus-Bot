
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


require "uri"
require "net/http"
require "json"

def initialize
  register_script("Search the Internet with Google.")

  register_command("g",       :cmd_g,       1, 0, nil, "Search for web pages using Google.")
  register_command("gimage",  :cmd_gimage,  1, 0, nil, "Search for images using Google.")
  register_command("gvideo",  :cmd_gvideo,  1, 0, nil, "Search for videos using Google.")
  register_command("gbook",   :cmd_gbook,   1, 0, nil, "Search books using Google.")
  register_command("gpatent", :cmd_gpatent, 1, 0, nil, "Search patents using Google.")
  register_command("gblog",   :cmd_gblog,   1, 0, nil, "Search blogs using Google.")
  register_command("gnews",   :cmd_gnews,   1, 0, nil, "Search news using Google.")
end

def cmd_g(msg, params)
  msg.reply(getResult(params[0], "web"))
end

def cmd_gimage(msg, params)
  msg.reply(getResult(params[0], "images"))
end

def cmd_gvideo(msg, params)
  msg.reply(getResult(params[0], "video"))
end

def cmd_gpatent(msg, params)
  msg.reply(getResult(params[0], "patent"))
end

def cmd_gbook(msg, params)
  msg.reply(getResult(params[0], "books"))
end

def cmd_gnews(msg, params)
  msg.reply(getResult(params[0], "news"))
end

def cmd_gblog(msg, params)
  msg.reply(getResult(params[0], "blogs"))
end


def getResult(query, type)
  $log.debug('google') { "Searching #{type} for #{query}" }

  query = URI.escape(query)

  uri = URI("https://ajax.googleapis.com/ajax/services/search/#{type}?v=1.0&q=#{query}")

  http      = Net::HTTP.new(uri.host, uri.port)
  request   = Net::HTTP::Get.new(uri.request_uri)

  request.initialize_http_header({"User-Agent" => get_config("useragent", "terminus-bot.net")})
  http.use_ssl = true

  response  = http.request(request)

  if response.code != "200"
    return "There was a problem with the search. Sorry! Response code was #{response.code}."
  end
  
  response = JSON.parse(response.body)

  results = Array.new
  limit = get_config("resultlimit", 3).to_i

  response["responseData"]["results"].each_with_index do |result, num|

    break if num >= limit

    case type

      when "web"
        results << "\02#{result["titleNoFormatting"]}\02 - #{result["url"]}"

      when "images"
        results << "\02#{result["titleNoFormatting"]}\02 - #{result["url"]}"

      when "books"
        results << "\02#{result["titleNoFormatting"]}\02 by #{result["authors"]} - #{URI.unescape(result["url"])} - #{result["bookId"]} - Published: #{result["publishedYear"]} - #{result["pageCount"]} Pages"

      when "news"
        results << "\02#{result["titleNoFormatting"]}\02 - #{URI.unescape(result["url"])}"

      when "blogs"
        results << "\02#{result["titleNoFormatting"]}\02 by #{result["author"]} - #{result["postUrl"]} - Published #{result["publishedDate"]}"

      when "patent"
        results << "\02#{result["titleNoFormatting"]}\02 - #{URI.unescape(result["url"])} - assigned to #{result["assignee"]} - #{result["patentNumber"]} (#{result["patentStatus"]}) - Applied for on: #{result["applicationDate"]}"

      when "video"
        results << "\02#{result["titleNoFormatting"]}\02 - #{result["playUrl"]}"

    end

  end

  results.empty? ? "No results." : results
end
