#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

require "strscan"
require "htmlentities"

  raise "urbandict script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Look up words on UrbanDictionary.com.'

command 'ud', 'Fetch the definition of a word from UrbanDictionary.com. If no parameter is given, fetch a random definition.' do
  if @params.empty?
    do_lookup "https://www.urbandictionary.com/random.php"
    next
  end

  word = URI.encode @params.join ' '

  url = "http://www.urbandictionary.com/define.php?term=#{word}"

  do_lookup url
end

helpers do
  def do_lookup url
    $log.debug('urbandict.do_lookup') { url }

    Bot.http_get(URI(url)) do |http|
      page  = StringScanner.new http.response.force_encoding 'UTF-8'

      defs  = []
      count = 0
      max   = get_config(:max, 1).to_i

      page.skip_until /class=.word.>/i
      word = page.scan_until /<\/td>/i
      word = clean_result word[0..word.length-7]
      word = HTMLEntities.new.decode word

      while page.skip_until(/<div class="definition">/i) != nil and count < max
        count += 1

        d = page.scan_until /<\/div>/i

        d = clean_result d[0..d.length - 7] rescue "I wasn't able to parse this definition."

        d = HTMLEntities.new.decode d

        defs << "\02[#{word}]\02 #{d}"
      end

      if count == 0
        reply "I was not able to find any definitions for that word."
      else
        reply defs, false
      end

    end
  end


  def clean_result result
    result.strip.gsub(/<[^>]*>/, "").gsub(/[\n\s]+/, " ")
  end

end
