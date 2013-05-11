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

need_module! 'url_handler'
need_module! 'http'

register 'Fetch statuses from Twitter.'

url /\/\/(www\.)?twitter\.com\/.+status/ do
  $log.info('twitter.url') { @uri.inspect }

  # TODO: Get the latest status for a linked user.                   
  # TODO: API v1 is deprecated. v1.1 requires OAuth bullshit. Open to
  #       suggestions on how to deal with this.                      

  if @uri.fragment
    match = @uri.fragment.match(/status(es)?\/(?<id>[0-9]+)/)
  end

  unless match
    match = @uri.path.match(/status(es)?\/(?<id>[0-9]+)/)

    return false unless match
  end

  id = URI.escape match[:id]
  api = URI("https://api.twitter.com/1/statuses/show.json?id=#{id}")

  http_get(api, {}, true) do |http|
    json = MultiJson.load(http.response)

    next if json['errors']

    text   = html_decode(json['text']).gsub(/[\r\n[[:cntrl:]]]/, '')
    author = json['user']['screen_name']

    reply "\02<@#{author}>\02 #{text}", false
  end

end

# vim: set tabstop=2 expandtab:
