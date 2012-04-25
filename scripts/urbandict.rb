
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


require "strscan"
require "htmlentities"

def initialize
  raise "urbandict script requires the http_client module" unless defined? Bot.http_get

  register_script("Look up words on UrbanDictionary.com.")
  register_command("ud",       :cmd_lookup,   0,  0, nil, "Fetch the definition of a word from UrbanDictionary.com. If no parameter is given, fetch a random definition.")

  @baseURL = "https://www.urbandictionary.com/define.php?term="
end

def cmd_lookup(msg, params)
  if params.empty?
    do_lookup("https://www.urbandictionary.com/random.php", msg)
    return
  end

  word = URI.encode(params[0])
  url = "#{@baseURL}#{word}"

  do_lookup(url, msg)
end

def do_lookup(url, msg)
  $log.debug('urbandict.do_lookup') { url }

  response = Bot.http_get(URI(url))

  if response == nil
    msg.reply("There was a problem looking up the definition for that word.")
    return
  end

  page = StringScanner.new(response[:response].body.force_encoding('UTF-8'))
  defs = Array.new
  count = 0
  max = get_config(:max, 1).to_i

  page.skip_until(/class=.word.>/i)
  word = page.scan_until(/<\/td>/i)
  word = clean_result(word[0..word.length-7])

  while page.skip_until(/<div class="definition">/i) != nil and count < max
    count += 1

    d = page.scan_until(/<\/div>/i)

    d = clean_result(d[0..d.length - 7]) rescue "I wasn't able to parse this definition."

    d = HTMLEntities.new.decode(d)

    defs << "\02[#{word}]\02 #{d}"
  end
  
  if count == 0
    msg.reply("I was not able to find any definitions for that word.")
  else
    msg.reply(defs, false)
  end
end


def clean_result(result)
  result.strip.gsub(/<[^>]*>/, "").gsub(/[\n\s]+/, " ")
end
