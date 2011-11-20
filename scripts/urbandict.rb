
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
require "htmlentities"

def initialize
  register_script("urbandict", "Look up words on UrbanDictionary.com.")
  register_command("ud", :lookup,   1,  0, "Fetch definition of word from UrbanDictionary.com.")

  @baseURL = "http://www.urbandictionary.com/define.php?term="
end

def lookup(msg, params)
  $log.debug('urbandict.lookup') { "Getting definition for #{params[0]}" }

  word = URI.encode(params[0])
  url = "#{@baseURL}#{word}"

  page = StringScanner.new(Net::HTTP.get URI.parse(url))
  defs = Array.new
  count = 0

  while page.skip_until(/<div class="definition">/i) != nil and count < Integer(get_config("definitions", 1))
    count += 1

    d = page.scan_until(/<\/div>/i)

    d = d[0..d.length - 7].strip.gsub(/<[^>]*>/, "").gsub(/[\n\s]+/, " ") rescue "I wasn't able to parse this definition."

    d = HTMLEntities.new.decode(d)

    defs << "\02[#{params[0]}]\02 #{d}"
  end
  
  if count == 0
    msg.reply("I was not able to find any definitions for that word.")
  else
    msg.reply(defs, false)
  end
     
end

