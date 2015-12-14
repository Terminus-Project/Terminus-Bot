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

need_module! 'http', 'url_handler'

register 'Fetch information from deviantART.'

url(/\/\/([^\.]+)\.deviantart\.com\/art\/.+|fav\.me/) do
  $log.info('deviantart.url') { @uri.inspect }

  title_handler @uri
end

url(/\/[\w-]+_by_[\w-]+-d[0-9A-Za-z]{5,8}+.\w{3}$/) do
  $log.info('deviantart.url') { @uri.inspect }

  match = @uri.to_s.match(/_by_.+-(?<id>d[0-9A-Za-z]{5,8})\.\w{3}/)

  next unless match

  title_handler "http://fav.me/#{match[:id]}", true
end

helpers do
  def title_handler uri, show_uri = false
    args = {
      :url => uri.to_s
    }

    api = URI('https://backend.deviantart.com/oembed')

    http_get(api, args, true) do |http|
      data = MultiJson.load http.response

      reply "#{data["provider_name"]}:#{" #{uri}" if show_uri} \02#{data["title"]}\02 by \02#{data["author_name"]}\02 - #{data["category"]} - #{data["width"]}x#{data["height"]}", false
    end
  end
end
# vim: set tabstop=2 expandtab:
