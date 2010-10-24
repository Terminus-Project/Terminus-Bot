
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
  $bot.modHelp.registerModule("IMDB", "Look up movies on the Internet Movie Database.")

  $bot.modHelp.registerCommand("IMDB", "imdb", "Find information about a movie by searching the Internet Movie Database.", "title")
end

#curl -e http://www.my-ajax-site.com \
#        'http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=hello%20world&langpair=en%7Cit'
#

def cmd_imdb(message)
  if message.msgArr.length < 2
    reply(message, "Usage: imdb #{UNDERLINE}title#{NORMAL}")
  else
    info = getMovie(message.args)
    reply(message, info, false)
  end
end


def getMovie(title)
  $log.debug('imdb') { "Getting info for movie #{title}." }

  title = URI.escape(title)

  url = "http://www.deanclatworthy.com/imdb/?q=#{title}"

  page = Net::HTTP.get URI.parse(url)

  if page == "n/a"
    return "I was not able to find a movie with that title. Please as exact as possible."
  end

  page = JSON.parse(page)

  return "#{BOLD}#{page["title"]}#{NORMAL} - Rating: #{page["rating"].gsub(/<.*>/, "")} (#{page["votes"]} votes) - Genres: #{page["genres"]} - Languages: #{page["languages"].gsub(/&.*;/, "")} - USA Screens: #{page["usascreens"]} - #{page["imdburl"]}"
end
