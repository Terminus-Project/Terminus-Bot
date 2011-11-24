
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

module IRC
  class Message
    attr_reader :origin, :destination, :type, :text, :raw, :raw_arr, :nick, :connection

    # Parse the str as an IRC message and fire appropriate events.
    def initialize(connection, str)

      @connection = connection

      arr = str.split
      
      @raw_arr = arr
      @raw = str

      if str[0] == ":"
        # This will be almost all messages.

        @origin = arr[0][1..arr[0].length-1]
        @type = arr[1]
        @destination = arr[2] # Not always the destination. Oh well.

        # This won't always succeed. Kind of derfy, but easier than
        # trying to handle every single message type case-by-case
        # (see old Terminus-Bot bot.rb).
        begin
          @nick = @origin.split("!")[0]
        rescue
          @nick = ""
        end

        # Grab the text portion, as in
        # :origin PRIVMSG #dest :THIS TEXT
        if str =~ /\A:[^:]+:(.+)\Z/
          @text = $1
        else
          @text = ""
        end

      else
        # Server PINGs. Not much else.

        @type = arr[0]
        @origin = ""
        @destination = ""

        if str =~ /.+:(.+)\Z/
          @text = $1
        else
          @text = ""
        end
      end

      $bot.events.run(:raw, self)  # Not currently used.
                                   # Leave in for scripts or remove?
      
      $bot.events.run(@type, self) # The most important line in this file!
                                   # Also the reason we can't use symbols for
                                   # most event names. :-(
    end

    # Reply to a message. If an array is given, send each reply separately.
    def reply(str, prefix = true)
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
      if @destination.start_with? "#"
        str = "PRIVMSG #{@destination} :#{prefix ? @nick + ": " : ""}#{truncate(str, @destination)}"

        @connection.raw(str)
      else
        str = "NOTICE #{@nick} :#{truncate(str, @nick, true)}"

        if str.length > 512
          str = str[0..512]
        end

        @connection.raw(str)
      end
    end

    # Attempt to truncate messages in such a way that the maximum
    # amount of space possible is used. This assumes the server will
    # send a full 512 bytes to a client.
    # TODO: This works perfectly, but servers don't seem to send 512 bytes
    #       per message! Figure out how to make this work well without just
    #       picking an arbitrary, shorter length.
    def truncate(message, destination, notice = false)
        prefix_length = @connection.nick.length +
                        @connection.user.length +
                        @connection.client_host.length +
                        destination.length +
                        13
        prefix_length += 1 unless notice

        oversize = (prefix_length + message.length) - 512

        $log.debug("Message.truncate") { "Oversize length: #{oversize} (Prefix: #{prefix_length}, Message: #{message.length})" }

        if oversize > 0
          return message[0..511-prefix_length]
        end

        return message
    end

    # Return true if this message's origin appears to be the bot.
    def me?
      return @connection.nick == @nick
    end

    # Return true if this message doesn't appear to have been sent in a
    # channel.
    def private?
      # TODO: Use CHANTYPES from 003.
      return (not @destination.start_with? "#" and not @destination.start_with? "&")
    end

    # This has to be separate from our method_missing cheat below because
    # raw is apparently an existing function. Oops! Better than overriding
    # send, though.
    def raw(*args)
      @connection.raw(*args)
    end

    # Cheat mode for sending things to the owning connection. Useful for
    # scripts.
    def method_missing(name, *args, &block)
      if @connection.respond_to? name
        @connection.send(name, *args, &block)
      else
        $log.error("Message.method_missing") { "Attempted to call nonexistent method #{name}" }
        throw NoMethodError.new("Attempted to call a nonexistent method #{name}", name, args)
      end
    end
  end
end
