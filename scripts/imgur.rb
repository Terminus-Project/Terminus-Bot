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

register 'Fetch information from Imgur.'

# XXX - /gallery/ links fuck this up
url /\/\/((www|i)\.)?imgur\.com\// do
  $log.info('imgur.url') { @uri.inspect }

  match = @uri.path.match(/\/(?<album>(a|gallery)\/)?(?<hash>[^\.]+)(?<extension>\.[a-z]{3})?/)

  next unless match

  arg = URI.escape match[:hash]
  type = match[:album] ? 'album' : 'image'
  api = URI("https://api.imgur.com/2/#{type}/#{arg}.json")

  http_get(api, {}, true) do |http|
    data = MultiJson.load http.response

    case type
    when 'image'
      data = data['image']['image']

      title = data['title'] ? data['title'] : 'No Title'

      reply "imgur: \02#{title}\02 - #{data["width"]}x#{data["height"]} #{data["type"]}#{" (animated)" if data["animated"] == 'true'}", false

    when 'album'
      data = data['album']

      title = data['title'] ? data['title'] : 'No Title'

      reply "imgur album: \02#{title}\02 - #{data["images"].length} images", false

    end

  end
end

# vim: set tabstop=2 expandtab:
