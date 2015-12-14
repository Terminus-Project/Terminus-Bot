#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Check if web services are available.'


command 'check', 'Check service availability. Syntax: uri' do
  argc! 1

  uri = URI(@params.first)

   # TODO: Support more protocols (TCP, SSH, etc.)

  case uri.scheme
  when 'http', 'https'
    check_http uri

  else
    raise 'unsupported protocol'
  end
end

helpers do

  def check_http uri
    start = Time.now.to_f

    http_get uri, {}, false, {:redirects => 0} do |http|
      if http.error
        raise http.error.to_s
      end

      time = ((Time.now.to_f - start) * 1000).to_i

      data = {
        'Response Time (ms)' => time,
        'Response Code' => http.response_header.status
      }

      reply data
    end
  end

  def check_tcp host, port
    # XXX
  end

end

# vim: set tabstop=2 expandtab:
