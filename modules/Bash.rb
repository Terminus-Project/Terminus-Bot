
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

def initialize
  registerModule("Bash", "Fetch quotations from Bash.org.")

  registerCommand("Bash", "bash", "Retrieve a random quotation from bash.org.", "")
end

def cmd_bash(message)
  $log.debug('bash') { "Getting random quotation from bash.org." }

  url = "http://bash.org/?random1"

  begin
    page = StringScanner.new(Net::HTTP.get URI.parse(url))

    page.skip_until(/<p class="quote">/i)
    page.skip_until(/<b>/i)

    id = page.scan_until(/<\/b>/i)
    id = id[0..id.length-5]

    link = "http://bash.org/?#{id[1..id.length-1]}"

    page.skip_until(/<p class="qt">/i)
    result = page.scan_until(/<\/p>/i)

    coder = HTMLEntities.new

    result = coder.decode(result)
    result = result[0..result.length-5]

    result = result.split("<br />")

    msg = Array.new
    msg << "Bash.org quote #{id}: #{link}"

    result.each { |line|
      msg << line.lstrip
    }

    if msg.length > 4
      msg.each { |msg|
        sendNotice(message.speaker.nick, msg)
      }
    else
      reply(message, msg, false)
    end

  rescue => e
    reply(message, "I wasn't able to get a quotation. #{e}", true)
  end
     
end

