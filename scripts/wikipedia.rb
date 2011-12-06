
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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


require "net/http"
require "uri"
require "json"

WIKI_API_URL = "http://en.wikipedia.org/w/api.php?action=query&format=json"

def initialize
  register_script("Perform Wikipedia look-ups.")

  register_command("wiki", :cmd_wiki, 1, 0, "Provide a link to the given Wikipedia page, corrected for redirects.")
end

def cmd_wiki(msg, params)
  
  $log.debug('wikipedia.cmd_wiki') { "Getting Wikipedia page for #{params[0]}" }

  url = WIKI_API_URL + "&titles=" + URI.escape(params[0])
  url += "&redirects"

  reply = JSON.parse(Net::HTTP.get URI.parse(url))

  if reply["query"]["pages"].has_key? "-1"
    msg.reply("No results.")
    return
  end

  lines = Array.new

  reply["query"]["pages"].each do |id, data|

    link_title = data["title"].gsub(/\s/, "_")
    lines << "#{data["title"]}: http://en.wikipedia.org/wiki/#{URI.escape(link_title)}"

  end

  msg.reply(lines, false)
end
