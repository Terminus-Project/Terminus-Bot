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

module Bot

  module IRCMacros

    def send_privmsg dest, msg
      raw "PRIVMSG #{dest} :#{msg}"
    end

    def send_notice dest, msg
      raw "NOTICE #{dest} :#{msg}"
    end

    def send_mode target, modes
      raw "MODE #{target} #{modes}"
    end

    def send_nick nick
      raw "NICK #{nick}"
    end

    def send_join channel
      if channel.is_a? Array
        buf = []

        channel.each do |c|
          buf << c
          
          if buf.length == 4
            send_join channel.join(',')
            buf.clear
          end
        end

        send_join buf.join(',') unless buf.empty?
      elsif channel.is_a? Hash
        buf, keys = [], []

        channel.each do |c, k|
          buf << c
          keys << (k.empty? ? k : 'x')
          
          if buf.length == 4
            send_join "#{buf.join(',')} #{keys.join(',')}"
            buf.clear
            keys.clear
          end
        end
        send_join "#{buf.join(',')} #{keys.join(',')}" unless buf.empty?
      else
        raw "JOIN #{channel}"
      end
    end

    def send_part channel, message = ""
      raw "PART #{channel} :#{message}"
    end

    def send_kick channel, target, message = ""
      raw "KICK #{channel} #{target} :#{message}"
    end

    def send_who target
      raw "WHO #{target}"
    end

    def send_whois target, server = ""
      raw "WHOIS #{target} #{server}"
    end

  end

end
