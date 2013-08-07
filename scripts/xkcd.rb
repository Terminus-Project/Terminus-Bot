#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2013 Kyle Johnson <kyle@vacantminded.com>
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

need_module! 'http'

register 'Interface with the XKCD API.'

url /\/\/(www\.)?xkcd\.com\/[0-9]+/ do
  match = @uri.path.match(/^\/(?<id>[0-9]+)\/?/)

  if match
    get_comic_info match[:id]
  end

  if @uri.path == '/'
    get_comic_info
  end
end

helpers do

  def get_comic_info id
    uri = URI("https://xkcd.com/#{id}/info.0.json")

    json_get uri do |json|
      reply_without_prefix "Comic for #{json['year']}-#{json['month']}-#{json['day']}" => json['title']
    end
  end

end

# vim: set tabstop=2 expandtab:
