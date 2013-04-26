#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

need_module! 'url_handler'
need_module! 'http'

require 'multi_json'
require 'uri'

register 'Perform Wikipedia look-ups.'

command 'wiki', 'Search Wikipedia for the given text.' do
  argc! 1

  search @params.first
end

url /\/\/[^\.]+\.wikipedia\.org\/wiki\/.+/ do
  site = @uri.host.split(/\./, 2).first
  page = URI.decode @uri.path.match(/\/wiki\/(?<page>.+)/)[:page]

  search page, site, true, false
end

helpers do
  def search query, site = get_config(:site, 'en'), hide_errors = false, include_link = true
    $log.info('wikipedia.search') { "Searching Wikipedia (#{site}) for #{query}" }


    uri = URI("https://#{site}.wikipedia.org/w/api.php")

    opts = {
      :action   => :query,
      :format   => :json,
      :srsearch => query,
      :limit    => 1,
      :list     => :search
    }

    http_get(uri, opts, hide_errors) do |http|
      response = MultiJson.load http.response

      if not response['query'] or response['query']['search'].empty?
        reply 'No results.' unless hide_errors
        next
      end

      output response['query']['search'].first, include_link
    end
  end

  def output data, include_link
    link_title = data['title'].gsub(/\s/, "_")
    link = "https://en.wikipedia.org/wiki/#{URI.escape(link_title)}"

    # .gsub ALL THE THINGS!
    snippet = data['snippet'].gsub(/<[^>]+>/, '').gsub(/\s+/, ' ').gsub(/\s([[:punct:]]+)\s/, '\1 ')
    snippet << link if include_link

    data = { 
      data['title'] => snippet
    }

    reply "#{data.to_s_irc}", false
  end
end
