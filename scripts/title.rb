
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
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
require "strscan"

def initialize
  register_script("title", "Fetches titles for URLs spoken in channels.")

  register_event("PRIVMSG", :on_message)
end

def on_message(msg)
  return unless get_config("enabled", "false") == "true"

  msg.text.scan(/http:\/\/[^\s]+/) { |match|
    get_title(msg, match)
  }
end

def get_title(msg, url)
  begin
    $log.debug('title.get_title') { "Getting title for #{url}" }

    page = StringScanner.new(Net::HTTP.get URI.parse(url))

    page.skip_until(/<title>/i)
    title = page.scan_until(/<\/title>/i)
    title = title[0..title.length - 9].strip.gsub(/[\n\s]+/, " ")

    msg.reply(title, false)
  rescue => e
    $log.debug('title.get_title') { "Error getting title for #{url}: #{e}" }
    return
  end
end
