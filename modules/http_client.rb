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

require "uri"
require 'cgi'

# EventMachine doesn't send a User-agent header. Many sites require it.
module EventMachine
  module Protocols
    class HttpClient2
      class Request

        def send_request
          headers = [
            "#{@args[:verb]} #{@args[:uri]} HTTP/#{@args[:version] or "1.1"}",
            "Host: #{@args[:host_header] or "_"}"
          ]

          headers.concat(@args[:headers]) unless @args[:headers] == nil
          headers << "\r\n"

          @conn.send_data headers.join("\r\n")
        end

      end
    end
  end
end

module Bot

  MODULE_LOADED_HTTP  = true
  MODULE_VERSION_HTTP = 0.2

  def self.http_get(uri, query_hash = nil, &block)
    uri.query = hash_to_query(query_hash) unless query_hash == nil
    http_request(uri, true, &block)
  end

  def self.http_post(uri, query_hash = nil, &block)
    uri.query = hash_to_query(query_hash) unless query_hash == nil
    http_request(uri, false, &block)
  end

  def self.hash_to_query(hash)
    hash.map {|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join('&')
  end

  # Should not be called directly.
  def self.http_request(uri, get, limit = Config[:modules][:http_client][:redirects], redirected = false, &block)
    return nil if limit == 0

    $log.debug("Bot.http_request") { uri }

    ua = Config[:modules][:http_client][:user_agent] || "Terminus-Bot (http://terminus-bot.net/)"

    # TODO: Let callers add headers.
    headers = [
      "User-agent: %s" % ua
    ]

    conn = EM::Protocols::HttpClient2.connect(:host => uri.host,
                                              :port => uri.port,
                                              :ssl => (uri.scheme == "https"))

    conn.comm_inactivity_timeout = Config[:modules][:http_client][:timeout] or 5

    path = uri.path
    path << "?%s" % uri.query unless uri.query == nil

    args = {:uri => path, :headers => headers}

    req = (get ? conn.get(args) : conn.post(args))

    req.callback do |response|
      $log.debug("Bot.http_request") { response.status }

      case response.status

      when 300..399
        location = URI(response.headers['location'][0])

        $log.debug("Bot.http_request") { "Redirection: #{uri} -> #{location} (#{limit})" }

        http_request(location, get, limit - 1, true, &block)

      else
        block.call response, uri, redirected

      end
    end
  end
end
