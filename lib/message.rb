#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
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


module Bot
  INCOMING_REGEX = /^(:(?<prefix>((?<nick>[^!]+)!(?<user>[^@]+)@(?<host>[^ ]+)|[^ ]+)) )?((?<numeric>[0-9]{3})|(?<command>[^ ]+))( (?<destination>[^:][^ ]*))?( :(?<text>.*)| (?<parameters>.*))?$/

  class Message

    attr_reader :origin, :type, :text, :parameters,
      :raw_str, :raw_arr, :nick, :nick_canon, :user, :host, :connection
    
    # Parse the str as an IRC message
    def initialize connection, str, outgoing = false
      arr = str.split

      @raw_str, @raw_arr = str, arr
      @connection = connection

      @raw_str.freeze
      @raw_arr.freeze
      @outgoing.freeze

      if outgoing

        @nick = connection.nick
        @user = connection.user
        @host = connection.client_host

        @origin = "#{@nick}!#{@user}@#{@host}"

        @type = arr[0].to_sym
        @destination = arr[1]

        @text = (str =~ /\A([^ ]+\s){1,2}:(.+)\Z/ ? $2 : "")

      else
        match = str.match INCOMING_REGEX

        unless match
          $log.error('message.initialize') { "Match error on: #{str}" }
        end

        @origin       = match[:prefix]
        @type         = (match[:command] || match[:numeric]).to_sym
        @destination  = match[:destination]

        @nick         = match[:nick]
        @user         = match[:user]
        @host         = match[:host]

        @text         = match[:text]
        @parameters   = match[:parameters]
      end

      @nick.freeze
      @user.freeze
      @host.freeze
      @text.freeze
      @origin.freeze
      @type.freeze
      @destination.freeze
    end

    # Reply to a message. If an array is given, send each reply separately.
    def reply str, prefix = true
      if str.kind_of? Array
        str.each do |this_str|
          send_reply this_str, prefix
        end
      else
        send_reply str, prefix
      end
    end

    # Actually send the reply. If prefix is true, prefix each message with the
    # triggering user's nick. If replying in private, never use a prefix, and
    # reply with NOTICE instead.
    def send_reply str, prefix
      if str.empty?
        str = "I tried to send you an empty message. Oops!"
      end

      # TODO: Hold additional content for later sending or something.
      #       Just don't try to send it all in multiple messages without
      #       the user asking for it!
      unless self.private?
        str = "#{@nick}: #{str}" if prefix

        send_privmsg @destination, str
      else
        send_notice @nick, str
      end
    end

    def raw *args
      @connection.raw *args
    end

    # Attempt to truncate messages in such a way that the maximum
    # amount of space possible is used. This assumes the server will
    # send a full 512 bytes to a client with exactly 1459 format.
    def truncate message, destination, notice = false
      prefix_length = @connection.nick.length +
        @connection.user.length +
        @connection.client_host.length +
        destination.length +
        15

      # PRIVMSG is 1 char longer than NOTICE
      prefix_length += 1 unless notice

      if (prefix_length + message.length) - 512 > 0
        return message[0..511-prefix_length]
      end

      message
    end

    def send_privmsg target, str
      raw "PRIVMSG #{target} :#{truncate str, target}"
    end

    def send_notice target, str
      raw "NOTICE #{target} :#{truncate str, target, true}"
    end

    # Return true if this message's origin appears to be the bot.
    def me?
      nick_canon == @connection.canonize(@connection.nick)
    end


    # Should not be called externally.
    def strip str
      str.gsub /(\x0F|\x1D|\02|\03([0-9]{1,2}(,[0-9]{1,2})?)?)/, ""
    end

    # Return the message with formatting stripped.
    def stripped
      @stripped ||= strip @text
    end

    # Apply CASEMAPPING to the nick and return it.
    def nick_canon
      @nick_canon ||= @connection.canonize @nick
    end

    # Apply CASEMAPPING to the destination and return it.
    def destination_canon
      @destination_canon ||= @connection.canonize destination
    end

    def destination
      @destination || @text
    end

    # Return true if this message doesn't appear to have been sent in a
    # channel.
    def private?
      return true if @destination == nil

      @private ||= (not @connection.support("CHANTYPES", "#&").include? @destination.chr)
    end

    def op?
      private? or @connection.channels[destination_canon].op? @nick
    end

    def half_op?
      private? or @connection.channels[destination_canon].half_op? @nick
    end

    def voice?
      private? or @connection.channels[destination_canon].voice? @nick
    end

  end
end
