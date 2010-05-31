
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
require "strscan"


def cmd_title(message)
  if message.args =~ /(https?:\/\/.+\..*)/
    $log.debug('http') { "Getting title for #{$1}" }

    page = StringScanner.new(Net::HTTP.get URI.parse($1))

    page.skip_until(/<title>/i)
    title = page.scan_until(/<\/title>/i)
    title = title[0..title.length - 9].strip.gsub(/\n/, " ").gsub(/\s+/, " ") rescue "I was unable to determine the title of the page."
    
    reply(message, title, true)
     
  else
    reply(message, "That doesn't look like a valid HTTP URL.", true)
  end
end

