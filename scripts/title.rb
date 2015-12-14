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

need_module! 'http', 'url_handler'

require 'strscan'

register 'Fetches titles for URLs spoken in channels.'

url do
  $log.info('title.url') { @uri.inspect }

  max_title_length = get_config(:max_title_length, 350).to_i

  http_get(@uri, {}, true) do |http|
    last = http.last_effective_url

    # http://stackoverflow.com/questions/1732348/regex-match-open-tags-except-xhtml-self-contained-tags

    # Note: I am not attempting to summon Zalgo, here. Our input is HTML that
    # may or may not be well-formed, and may in fact be not even be HTML. The
    # best we can do is try to find something that looks like a page title and
    # extract it. Thus: we are parsing HTML with regular expressions.

    begin
      page = StringScanner.new http.response

      page.skip_until(/<title[^>]*>/ix)
      title = page.scan_until(/<\/title[^>]*>/ix)

      next if title == nil

      title = title.match(/(?<title>.*)<\/title[^>]*>/)[:title]
      title = html_decode(title).gsub(/[[[:cntrl:]]\s]+/, ' ').strip

      next if title.empty?

      if title.length > max_title_length
        title = title[0..(max_title_length - 3)] + '...'
      end

      reply "\02Title on #{last.host}#{' (redirected)' unless http.redirects.zero?}:\02 #{title}", false
    rescue => e
      $log.error('title.get_title') { "Error getting title for #{@uri}: #{e} #{e.backtrace.join("\n")}" }
    end
  end

end

# vim: set tabstop=2 expandtab:
