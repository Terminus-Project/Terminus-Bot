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

module Bot

  raise 'url_handler module requires http_client module' unless defined? MODULE_LOADED_HTTP

  MODULE_LOADED_TITLE  = true
  MODULE_VERSION_TITLE = 0.1

  class URLHandlers

    def initialize
      @@handlers = {}
      @@default_handler = nil

      Bot::Events.create :PRIVMSG, self, :on_privmsg
    end

    def add_handler parent, regex = nil, &block
      if regex.nil?
        @@default_handler = { :owner => parent, :block => block }
        return
      end

      if @@handlers.has_key? regex
        raise "#{parent} attempted to add duplicate URL handler regex: #{regex}"
      end

      @@handlers[regex] = { :owner => parent, :block => block }
    end

    def delete_for parent
      @@handlers.reject! do |regex, handler|
        handler[:owner] == parent
      end

      @@default_handler = nil if @@default_handler[:owner] == parent
    end

    def on_privmsg msg
      URI.extract(msg.text, ['http', 'https']) do |uri|
        on_match msg, URI(uri)
      end
    end

    def on_match msg, uri
      $log.debug('URLHandlers.on_match') { uri.inspect }

      @@handlers.each do |regex, handler|
        if uri.host.match regex
          URLHandler.dispatch handler[:owner], uri, msg, &handler[:block]

          return
        end
      end

      return if @@default_handler.nil?

      URLHandler.dispatch @@default_handler[:owner],
        uri, msg, &@@default_handler[:block]
    end

  end

  class URLHandler < Command
    class << self
      def dispatch owner, uri, msg, &block
        self.new(owner, uri, msg).instance_eval &block
      end
    end

    def initialize owner, uri, msg
      @uri = uri
      super owner, msg, nil, ''
    end
  end

  class Script

    def url regex = nil, &block
      Bot::URL.add_handler self, regex, &block
    end
  
  end

  URL ||= URLHandlers.new
end

