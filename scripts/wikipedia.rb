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

require "json"

WIKI_API_URL = "https://en.wikipedia.org/w/api.php?action=query&format=json"

def initialize
  raise "wiki script requires the http_client module" unless defined? MODULE_LOADED_HTTP

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
