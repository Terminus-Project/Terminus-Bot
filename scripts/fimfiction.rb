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

require 'multi_json'

raise "fimfiction script requires the url_handler module" unless defined? MODULE_LOADED_URL_HANDLER

register 'Fetch information from FIMFiction.'

url /\/\/(www\.)?fimfiction\.net\/story\/[0-9]+\// do
  $log.info('fimfiction.url') { @uri.inspect }

  match = @uri.to_s.match(/\/story\/(?<id>[0-9]+)\//)

  args = {
    :story => match[:id]
  }

  api = URI('http://www.fimfiction.net/api/story.php')

  http_get(api, args, true) do |http|
    data = MultiJson.load(http.response)['story']

    rating  = data['content_rating_text']
    cats    = data['categories'].select {|cat, value| value }.keys.join(', ')
    title   = HTMLEntities.new.decode data['title']
    desc    = HTMLEntities.new.decode data['short_description']

    data = {
      "#{title} by #{data['author']['name']}" => [rating, desc, cats].join(' - '),
      'Status' => data['status']
    }

    reply data, false
  end
end
