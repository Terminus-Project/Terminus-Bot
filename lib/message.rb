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
  INCOMING_REGEX = /^(:(?<prefix>((?<nick>[^!]+)!(?<user>[^@]+)@(?<host>[^ ]+)|[^ ]+)) )?((?<numeric>[0-9]{3})|(?<command>[^ ]+))( (?<destination>[^:][^ ]*))?( :(?<text>.*)| (?<parameters>.*))?$/

  class Message

    attr_reader :origin, :type, :text, :parameters,
      :raw_str, :raw_arr, :nick, :nick_canon, :user, :host, :connection
    
    # Create a new {Message} from a raw IRC message.
    #
    # @param connection [IRCConnection] connection on which the message was
    #   sent or received
    # @param str [String] raw IRC line
    # @param outgoing [Boolean] true if the bot sent the message, false if not
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

        @text = (str =~ /^([^ ]+\s){1,2}:(.+)$/ ? $2 : "")

      else

        match = str.match INCOMING_REGEX

        unless match
          $log.error('message.initialize') { "Match error on: #{str}" }
          return
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

    # Check if the message was sent by or otherwise belongs to the bot.
    # @return [Boolean] true if the message belongs to the bot, false it not
    def me?
      nick_canon == @connection.canonize(@connection.nick)
    end

    # Strip IRC formatting data from string.
    # @todo move to String class
    # @param str [String] string to strip
    # @return [String] stripped string
    def strip str
      str.gsub /(\x0F|\x1D|\02|\03([0-9]{1,2}(,[0-9]{1,2})?)?)/, ""
    end

    # Return the message with IRC formatting stripped.
    #
    # Stripped text is memoized.
    #
    # @return [String] message text with formatting removed
    def stripped
      @stripped ||= strip @text
    end

    # Get the canonized nick that owns this message.
    #
    # CASEMAPPING from ISUPPORT is used.
    #
    # @see IRCConnection.canonize
    # @return [String] canonized IRC nick
    def nick_canon
      @nick_canon ||= @connection.canonize @nick
    end

    # Get the canonized nick that owns this message with prefix included.
    #
    # @param channel [String] channel to check for prefix
    # @see IRCConnection#canonize
    # @see ChannelUser#prefix
    # @return [String] canonized nick with prefix
    def nick_with_prefix channel
      channel = @connection.canonize(channel)
      prefix = @connection.channels[channel].users[nick_canon].prefix || ''

      "#{prefix}#{@nick}"
    end

    # Get the canonized message destination. This will (most likely) be a nick
    # or channel name.
    #
    # @see IRCConnection#canonize
    # @return [String] canonized message destination
    def destination_canon
      @destination_canon ||= @connection.canonize destination
    end

    # Get the message's destination. Not all messages necessarily *have* a
    # destination, but we try to choose a sane answer.
    #
    # @return [String] message destination
    def destination
      @destination || @text
    end

    # Check if the message was sent in private. CHANTYPES is used to determine
    # if the message was sent in a channel.
    #
    # @return [Boolean] false if message was private, true if not
    def query?
      return true if @destination == nil

      @query ||= (not @connection.support("CHANTYPES", "#&").include? @destination.chr)
    end
  end
end
