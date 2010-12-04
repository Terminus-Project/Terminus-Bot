
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

require "net/http"
require "uri"
require "json"

def initialize
  registerModule("Google", "Search the Internet with Google.")

  registerCommand("Google", "g", "Search for web pages using Google.", "query")
  registerCommand("Google", "gimage", "Search for images using Google.", "query")
  registerCommand("Google", "gvideo", "Search for images using Google.", "query")
  registerCommand("Google", "gbook", "Search for images using Google.", "query")
  registerCommand("Google", "gpatent", "Search for images using Google.", "query")
  registerCommand("Google", "gblog", "Search for images using Google.", "query")
  registerCommand("Google", "gnews", "Search for images using Google.", "query")

  default("useragent", "sinsira.net")
  default("resultLimit", 3)

  @baseURL = "http://ajax.googleapis.com/ajax/services/search/"
end

#curl -e http://www.my-ajax-site.com \
#        'http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=hello%20world&langpair=en%7Cit'
#

def cmd_g(message)
  if message.msgArr.length < 2
    reply(message, "Usage: #{UNDERLINE}query#{NORMAL}")
  else
    result = getResult(message.args, "web")
    reply(message, result)
  end
end

def cmd_gimage(message)
  if message.msgArr.length < 2
    reply(message, "Usage: #{UNDERLINE}query#{NORMAL}")
  else
    result = getResult(message.args, "images")
    reply(message, result)
  end
end

def cmd_gvideo(message)
  if message.msgArr.length < 2
    reply(message, "Usage: #{UNDERLINE}query#{NORMAL}")
  else
    result = getResult(message.args, "video")
    reply(message, result)
  end
end

def cmd_gpatent(message)
  if message.msgArr.length < 2
    reply(message, "Usage: #{UNDERLINE}query#{NORMAL}")
  else
    result = getResult(message.args, "patent")
    reply(message, result)
  end
end

def cmd_gbook(message)
  if message.msgArr.length < 2
    reply(message, "Usage: #{UNDERLINE}query#{NORMAL}")
  else
    result = getResult(message.args, "books")
    reply(message, result)
  end
end

def cmd_gnews(message)
  if message.msgArr.length < 2
    reply(message, "Usage: #{UNDERLINE}query#{NORMAL}")
  else
    result = getResult(message.args, "news")
    reply(message, result)
  end
end

def cmd_gblog(message)
  if message.msgArr.length < 2
    reply(message, "Usage: #{UNDERLINE}query#{NORMAL}")
  else
    result = getResult(message.args, "blogs")
    reply(message, result)
  end
end


def getResult(query, type)
  $log.debug('google') { "Searching web for #{query}" }

  query = URI.escape(query)
  url = "#{@baseURL}#{type}?v=1.0&q=#{query}"

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request.initialize_http_header({"User-Agent" => get("useragent")})
  response = http.request(request)

  if response.code != "200"
    return "There was a problem with the search. Sorry! Response code was #{response.code}."
  end
  
  response = JSON.parse(response.body)
  results = Array.new
  num = 0
  limit = get("resultLimit")

  response["responseData"]["results"].each { |result|
    break if num >= limit

    case type
      when "web"
        results << "#{BOLD}#{result["titleNoFormatting"]}#{NORMAL} - #{result["url"]}"
      when "images"
        results << "#{BOLD}#{result["titleNoFormatting"]}#{NORMAL} - #{result["url"]}"
      when "books"
        results << "#{BOLD}#{result["titleNoFormatting"]}#{NORMAL} by #{result["authors"]} - #{URI.unescape(result["url"])} - #{result["bookId"]} - Published #{result["publishedYear"]} - #{result["pageCount"]} Pages"
      when "news"
        results << "#{BOLD}#{result["titleNoFormatting"]}#{NORMAL} - #{URI.unescape(result["url"])}"
      when "blogs"
        results << "#{BOLD}#{result["titleNoFormatting"]}#{NORMAL} by #{result["author"]} - #{result["postUrl"]} - Published #{result["publishedDate"]}"
      when "patent"
        results << "#{BOLD}#{result["titleNoFormatting"]}#{NORMAL} - #{URI.unescape(result["url"])} - assigned to #{result["assignee"]} - #{result["patentNumber"]} (#{result["patentStatus"]}) - Applied for on: #{result["applicationDate"]}"
      when "video"
        results << "#{BOLD}#{result["titleNoFormatting"]}#{NORMAL} - #{result["url"]}"
    end
    num += 1
  }
  return results
end
