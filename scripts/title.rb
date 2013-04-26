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

need_module! 'http'
need_module! 'url_handler'

require 'strscan'
require 'htmlentities'

register 'Fetches titles for URLs spoken in channels.'

url do
  $log.info('title.url') { @uri.inspect }

  http_get(@uri, {}, true) do |http|
    last = http.last_effective_url

    begin
      page = StringScanner.new http.response

      page.skip_until /<title[^>]*>/ix
      title = page.scan_until /<\/title[^>]*>/ix

      next if title == nil

      title = HTMLEntities.new.decode title

      len = title.length - 9
      next if len <= 0

      title = title[0..len].strip.gsub(/[[[:cntrl:]]\s]+/, ' ').strip

      next if title.empty?

      reply "\02Title on #{last.host}#{' (redirected)' unless http.redirects.zero?}:\02 #{title}", false
    rescue => e
      $log.error('title.get_title') { "Error getting title for #{uri}: #{e} #{e.backtrace.join("\n")}" }
    end
  end

end

