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
  class Message

    attr_reader :origin, :destination, :type, :text, :raw_str, :raw_arr,
      :nick, :nick_canon, :user, :host, :connection
    
    # Parse the str as an IRC message and fire appropriate events.
    def initialize(connection, str, outgoing = false)
      arr = str.split

      @raw_str, @raw_arr = str, arr
      @connection = connection

      @raw_str.freeze
      @raw_arr.freeze
      @outgoing.freeze

      # TODO: This whole thing can be done with just one regex!

      if outgoing

        @nick = connection.nick
        @user = connection.user
        @host = connection.client_host

        @origin = "#{@nick}!#{@user}@#{@host}"

        @type = arr[0].to_sym
        @destination = arr[1]

        @text = (str =~ /\A([^ ]+\s){1,2}:(.+)\Z/ ? $2 : "")

      else

        if str[0] == ":"

          # This will be almost all messages.
          @origin = arr[0][1..arr[0].length-1]
          @type = arr[1].to_sym
          @destination = arr[2].gsub(/\A:?/, "") # Not always the destination. Oh well.

          if @origin =~ /\A([^ ]+)!([^ ]+)@([^ ]+)/
            @nick, @user, @host = $1, $2, $3
          else
            @nick, @user, @host = "", "", ""
          end

          # Grab the text portion, as in
          # :origin PRIVMSG #dest :THIS TEXT

          @text = (str =~ /\A:[^ ]+(\s[^ ]+){0,2}\s:(.+)\Z/ ? $2 : "")

        else
          # Server PINGs. Not much else.
          @type = arr[0].to_sym
          @origin, @destination = "", ""
          @nick, @user, @host = "", "", ""

          @text = (str =~ /.+:(.+)\Z/ ? $1 : "")
        end

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
    def reply(str, prefix = true)
      return if silent?

      if str.kind_of? Array
        str.each do |this_str|
          send_reply(this_str, prefix)
        end
      else
        send_reply(str, prefix)
      end
    end

    # Actually send the reply. If prefix is true, prefix each message with the
    # triggering user's nick. If replying in private, never use a prefix, and
    # reply with NOTICE instead.
    def send_reply(str, prefix)
      if str.empty?
        str = "I tried to send you an empty message. Oops!"
      end

      # TODO: Hold additional content for later sending or something.
      #       Just don't try to send it all in multiple messages without
      #       the user asking for it!
      unless self.private?
        str = "PRIVMSG #{@destination} :#{prefix ? "#{@nick}: " : ""}#{truncate(str, @destination)}"
      else
        str = "NOTICE #{@nick} :#{truncate(str, @nick, true)}"
      end

      @connection.raw(str)
    end

    def raw(*args)
      @connection.raw(*args)
    end

    # Attempt to truncate messages in such a way that the maximum
    # amount of space possible is used. This assumes the server will
    # send a full 512 bytes to a client with exactly 1459 format.
    def truncate(message, destination, notice = false)
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

    def send_privmsg(target, str)
      raw("PRIVMSG #{target} :#{truncate(str, target)}")
    end

    def send_notice(target, str)
      raw("NOTICE #{target} :#{truncate(str, target, true)}")
    end

    # Return true if this message's origin appears to be the bot.
    def me?
      nick_canon == @connection.canonize(@connection.nick)
    end


    # Should not be called externally.
    def strip(str)
      str.gsub(/(\x0F|\x1D|\02|\03([0-9]{1,2}(,[0-9]{1,2})?)?)/, "")
    end

    # Return the message with formatting stripped.
    def stripped
      @stripped ||= strip(@text)
    end

    # Apply CASEMAPPING to the nick and return it.
    def nick_canon
      @nick_canon ||= @connection.canonize @nick
    end

    # Apply CASEMAPPING to the destination and return it.
    def destination_canon
      @destination_canon ||= @connection.canonize @destination
    end

    # Return true if this message doesn't appear to have been sent in a
    # channel.
    def private?
      return true if @destination == nil

      not @connection.support("CHANTYPES", "#&").include? @destination.chr
    end

    def op?
      return true if private?
      @connection.channels[destination_canon].op? @nick
    end

    def half_op?
      return true if private?
      @connection.channels[destination_canon].half_op? @nick
    end

    def voice?
      return true if private?
      @connection.channels[destination_canon].voice? @nick
    end


    # Return true if this channel is listed in the silent setting.
    def silent?
      return false
      return false if self.private?

      silenced = Bot::Config[:core][:silent]

      return false if silenced == nil
      return false if silenced.empty?

      silenced.each_pair do |connection, channels|
        next unless connection == @connection.name
        next if channels.empty?

        channels = @connection.canonize(channels).split

        return true if channels.include? destination_canon
      end
    end

  end
end
