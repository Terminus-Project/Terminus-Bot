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

require "json"

raise "deviantart script requires the url_handler module" unless defined? MODULE_LOADED_URL_HANDLER

register 'Fetch information from deviantART.'

url /\/\/([^\.]+)\.deviantart\.com\/art\/.+|fav\.me/ do
  $log.info('deviantart.url') { @uri.inspect }

  args = {
    :url => uri.to_s
  }

  api = URI('https://backend.deviantart.com/oembed')

  http_get(api, args, true) do
    data = JSON.parse(http.response)

    reply "#{data["provider_name"]}: \02#{data["title"]}\02 by \02#{data["author_name"]}\02 - #{data["category"]} - #{data["width"]}x#{data["height"]} #{data["type"]}", false
  end
end

