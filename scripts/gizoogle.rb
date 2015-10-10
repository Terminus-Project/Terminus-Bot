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

require 'strscan'

need_module! 'http'

register 'Translate text using Gizoogle.'

command 'gizoogle', 'Translate text using Gizoogle' do
  argc! 1

  uri  = URI('http://www.gizoogle.net/textilizer.php')

  text = URI.encode @params.first
  body = "translatetext=#{text}"

  opts = {
    :head => {
      'Content-Type'    => 'application/x-www-form-urlencoded',
      'Content-Length'  => body.length
    },
    :body => body
  }

  http_post(uri, {}, false, opts) do |http|
    page = StringScanner.new http.response

    page.skip_until /<textarea[^>]*>/ix
    text = page.scan_until /<\/textarea[^>]*>/ix

    next if text == nil

    text = html_decode text[0..-12]

    text = text.gsub(/[[[:cntrl:]]\s]+/, ' ').strip

    reply text
  end
end

