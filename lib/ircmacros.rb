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

    # Send a PRIVMSG.
    # @param dest [String] message destination
    # @param msg [String] message body
    def send_privmsg dest, msg
      send_command 'PRIVMSG', dest, msg
    end
    
    # Send a CTCP ACTION.
    # @param dest [String] message destination
    # @param msg [String] message body
    def send_action dest, msg
      send_privmsg dest, "\001ACTION #{msg}\001"
    end

    # Send a NOTICE.
    # @param dest [String] message destination
    # @param msg [String] message body
    def send_notice dest, msg
      send_command 'NOTICE', dest, msg
    end

    # Send a MODE.
    # @param target [String] target channel or user
    # @param modes [String] modes to apply to target
    def send_mode target, modes
      send_command 'MODE', [target, modes]
    end

    # Change the bot's nick.
    # @param nick [String] new nick
    def send_nick nick
      send_command 'NICK', nick
    end

    # Join one or more channels.
    #
    # Accepts several types of parameters:
    #
    # * String: Single channel, or comma-separated list of channels to join.
    #   Sent as-is to server.
    # * Array: One channel per array item. JOINs are automatically compressed
    #   to fewer commands. Channels which the bot is already in are omitted.
    # * Hash: Channel name => channel key pairs. JOINs are automatically
    #   compressed as they are with the Array type. Channels which the bot is
    #   already in are omitted.
    #
    # @param channel [String, Array, Hash] channel or channels to join
    def send_join channel
      if channel.is_a? Array
        buf = []

        channel.each do |c|
          next if channels.include? c

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
          next if channels.include? c

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
        send_command 'JOIN', channel
      end
    end

    # Leave a channel.
    # @param channel [String] channel to leave
    # @param message [String] part reason
    def send_part channel, message = ""
      send_command 'PART', channel, message
    end

    # Kick a user from a channel.
    # @param channel [String] channel from which to kick the user
    # @param target [String] nick of the user to kick
    # @param message [String] kick reason
    def send_kick channel, target, message = ""
      send_command 'KICK', [channel, target], message
    end

    # Send a WHO for the given target.
    # @param target [String] the channel or user for which you want info
    def send_who target
      send_command 'WHO', target
    end

    # Send a WHOIS for the given user.
    # @param target [String] nick of the desired user
    # @param server [String] server (or nick a second time) to which the whois
    #   should be sent
    def send_whois target, server = ""
      send_command 'WHOIS', [target, server]
    end

    # Send a command to the server.
    #
    # Based on the command being sent, the message may be scheduled for certain
    # delivery priorities.
    # @param command [String] command to send
    # @param params [String, Array] list of parameters for the command
    # @param text [String] trailing argument, sent after a colon
    def send_command command, params = nil, text = nil
      buf = []

      command.upcase!

      buf << command
      
      if params
        if params.is_a? Array
          buf.concat params
        elsif params.is_a? String
          buf << params
        else
          raise "params (second function parameter) must be a String or Array"
        end
      end

      if text
        buf << ":#{text}"
      end

      buf = buf.join ' '

      case command
      when 'PRIVMSG', 'NOTICE'
        raw buf, :fast
      when 'PONG', 'QUIT'
        raw buf, :immediate
      else
        raw buf, :slow
      end
    end
  end

end
# vim: set tabstop=2 expandtab:
