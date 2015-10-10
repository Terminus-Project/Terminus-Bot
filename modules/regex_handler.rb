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

module Bot

  MODULE_LOADED_REGEX_HANDLER  = true
  MODULE_VERSION_REGEX_HANDLER = 0.1

  class RegexHandlers

    def initialize
      @@handlers = {}

      Bot::Events.create :PRIVMSG, self, :on_privmsg
    end

    def add_handler parent, regex, &block
      @@handlers[regex] ||= []
      @@handlers[regex] << { :owner => parent, :block => block }
    end

    def delete_for parent
      @@handlers.reject! do |regex, handlers|
        handlers.reject! do |handler|
          handler[:owner] == parent
        end

        handlers.empty?
      end
    end

    def on_privmsg msg
      return if msg.me?

      @@handlers.each do |regex, handlers|
        match = msg.stripped.match regex

        if match
          on_match msg, match, handlers
        end
      end
    end

    def on_match msg, match, handlers
      $log.debug('RegexHandlers.on_match') { match.inspect }

      handlers.each do |handler|
        RegexHandler.dispatch handler[:owner], msg, match, &handler[:block]
      end
    end
  end

  class RegexHandler < Command
    class << self
      def dispatch owner, msg, match, &block
      	return unless Bot::Flags.permit_message? owner, msg

        helpers &owner.get_helpers if owner.respond_to? :helpers

        self.new(owner, msg, match).instance_eval &block
      end
    end

    def initialize owner, msg, match
      @match = match
      super owner, msg, nil, ''
    end
  end

  class Script

    def regex regex, &block
      Bot::RegexHandlerManager.add_handler self, regex, &block
    end

  end

  RegexHandlerManager ||= RegexHandlers.new
end

# vim: set tabstop=2 expandtab:
