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

raise "wiki script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Perform Wikipedia look-ups.'

command 'wiki', 'Search Wikipedia for the given text.' do
  argc! 1

  $log.info('wikipedia.cmd_wiki') { "Getting Wikipedia page for #{@params.first}" }


  Bot.http_get(URI('http://en.wikipedia.org/w/api.php'), :action=> :query, :format => :json, :srsearch => @params.first, :limit => 1, :list => :search) do |http|
    response = JSON.parse http.response

    if response["query"]["search"].empty?
      reply "No results."
      next
    end

    data = response["query"]["search"][0]

    link_title = data["title"].gsub(/\s/, "_")

    # .gsub ALL THE THINGS!
    snippet = data["snippet"].gsub(/<[^>]+>/, '').gsub(/\s+/, ' ').gsub(/\s([[:punct:]]+)\s/, '\1 ')

    buf = "\02#{data["title"]}:\02 #{snippet}"
    buf << " https://en.wikipedia.org/wiki/#{URI.escape(link_title)}"

    reply buf, false
  end
end

