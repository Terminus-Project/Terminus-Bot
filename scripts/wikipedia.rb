
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


require "json"

WIKI_API_URL = "https://en.wikipedia.org/w/api.php?action=query&format=json"

def initialize
  raise "wiki script requires the http_client module" unless defined? Bot.http_get

  register_script("Perform Wikipedia look-ups.")

  register_command("wiki", :cmd_wiki, 1, 0, nil, "Provide a link to the given Wikipedia page, corrected for redirects.")
end

def cmd_wiki(msg, params)
  $log.info('wikipedia.cmd_wiki') { "Getting Wikipedia page for #{params[0]}" }

  uri = URI("#{WIKI_API_URL}&srsearch=#{URI.escape(params[0])}&limit=1&list=search")

  response = Bot.http_get(uri)

  if response == nil
    msg.reply("There was a problem with the search.")
    return
  end

  response = JSON.parse(response[:response].body.force_encoding("UTF-8"))

  if response["query"]["search"].empty?
    msg.reply("No results.")
    return
  end

  data = response["query"]["search"][0]

  link_title = data["title"].gsub(/\s/, "_")

  # .gsub ALL THE THINGS!
  snippet = data["snippet"].gsub(/<[^>]+>/, '').gsub(/\s+/, ' ').gsub(/\s([[:punct:]]+)\s/, '\1 ')

  buf = "\02#{data["title"]}:\02 #{snippet}"
  buf << " https://en.wikipedia.org/wiki/#{URI.escape(link_title)}"

  msg.reply(buf, false)
end
