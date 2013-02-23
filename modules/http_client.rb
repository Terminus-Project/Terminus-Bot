# 
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

require 'uri'
require 'em-http-request'

module Bot

  MODULE_LOADED_HTTP  = true
  MODULE_VERSION_HTTP = 0.2

  def self.http_get uri, query = {}, &block
    http_request uri, query, true, &block
  end

  def self.http_post uri, query = {}, &block
    http_request uri, query, false, &block
  end

  # Should not be called directly.
  def self.http_request uri, query, get, &block
    $log.debug("Bot.http_request") { uri }

    ua = Conf[:modules][:http_client][:user_agent] or "Terminus-Bot (http://terminus-bot.net/)"

    # TODO: Let callers add headers.

    http = EventMachine::HttpRequest.new(uri,
      :connect_timeout    => (Conf[:modules][:http_client][:timeout] or 5),
      :inactivity_timeout => (Conf[:modules][:http_client][:timeout] or 5)
    )
    
    args = {
      :query              => query,
      :head               => { 'User-agent' => ua },
      :redirects          => (Conf[:modules][:http_client][:redirects] or 10)
    }

    if get
      req = http.get  args
    else
      req = http.post args
    end

    req.callback { block.call(req) }

    req.errback do
      $log.error('Bot.http_request') { "#{uri} #{req.error}" }
    end
  end
end
