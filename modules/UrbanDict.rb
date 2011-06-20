
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
  registerModule("UrbanDict", "Look up words on UrbanDictionary.com.")

  registerCommand("UrbanDict", "ud", "Fetch definition of word from UrbanDictionary.com.", "word")
  @baseURL = "http://www.urbandictionary.com/define.php?term="

  default("maxDefinitions", 3)
end

def cmd_ud(message)
  if message.args.length == 0
    reply(message, "Please specify a word. See #{BOLD}HELP ud#{NORMAL} for more info.")
    return true
  end

  $log.debug('urbandict') { "Getting definition for #{message.args}" }

  word = URI.encode(message.args)
  url = "#{@baseURL}#{word}"

  page = StringScanner.new(Net::HTTP.get URI.parse(url))
  definitions = Array.new
  count = 0

  while page.skip_until(/<div class="definition">/i) != nil and count < get("maxDefinitions", 3)
    count += 1

    definition = page.scan_until(/<\/div>/i)

    definition = definition[0..definition.length - 7].strip.gsub(/\n/, " ").gsub(/\s+/, " ").gsub(/<[^>]*>/, " ") rescue "I wasn't able to parse this definition."

    definition = "#{definition[0..400-message.args.length-8]}..." if definition.length > 400-message.args.length-5

    definitions << "#{BOLD}[#{message.args}]#{NORMAL} #{definition}"
  end
  
  if count == 0
    reply(message, "I was not able to find any definitions for that word.")
  else
    reply(message, definitions, false)
  end
     
end

