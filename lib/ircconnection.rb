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

  class IRCConnection < EventMachine::Connection
    require 'timeout'

    include Bot::IRCMacros

    attr_reader :config, :name, :channels, :users,
      :client_host, :caps, :nick, :user, :realname,
      :bytes_sent, :bytes_received, :lines_sent, :lines_received

    # Create a new IRC connection.
    #
    # This function does several things:
    #
    # 1. Add itself to the {Bot::Connections} {Hash} using the network name as
    #   the key.
    # 2. Set up data structures for the connection.
    # 3. Set up events for the core connection event handlers (NICK, 001, etc.)
    # 4. Set up connection options in EventMachine.
    def initialize name
      Bot::Connections[name] = self

      @disconnecting   = false
      @reconnecting    = false
      @send_queue_slow = Queue.new
      @send_queue_fast = Queue.new
      @history         = []
      @isupport        = {}
      @buf             = BufferedTokenizer.new
      @client_host     = ""

      @bytes_sent     = 0
      @bytes_received = 0
      @lines_sent     = 0
      @lines_received = 0

      bind = Bot::Conf[:core][:bind]
      
      # XXX
      @caps = ClientCapabilities.new self if defined? MODULE_LOADED_CLIENT_CAPABILITIES

      @name = name
      @name.freeze

      @nick     = Bot::Conf[:core][:nick]
      @user     = Bot::Conf[:core][:user]
      @realname = Bot::Conf[:core][:realname]
      @config   = Bot::Conf[:servers][name]

      $log.debug("IRCConnection.initialize #{name}") { "#{@config[:address]}:#{@config[:port]} #{@nick}!#{@user}@ #{@realname}" }

      Events.create :NICK,  self, :on_nick
      Events.create :"433", self, :on_nick_in_use
      Events.create :"001", self, :on_registered
      Events.create :"005", self, :on_isupport

      Flags.add_server name.to_s

      timeout = @config[:timeout] rescue 0
      set_comm_inactivity_timeout timeout

      $log.debug("IRCConnection.initialize #{name}") { "Done preparing connection." }
    end

    # Cleanly disconnect from IRC.
    #
    # A quit message is added to the outgoing queue, which is then flushed.
    #
    # @param quit_message [String] message to send as the bot's quit
    #   message/reason
    def disconnect quit_message = "Terminus-Bot: Terminating"
      send_command 'QUIT', [], quit_message

      @disconnecting = true

      flush_queue
    end

    # Reconnect to IRC.
    #
    # Send a quit message first. If the connection was lost, don't attempt to
    # send a quit message. Reconnection is attempted after the duration
    # specified in the configuration value for `core/reconwait`
    #
    # @see IRCConnection#unbind
    #
    # @param lost_connection [Boolean]
    def reconnect lost_connection = false
      unless lost_connection
        send_command 'QUIT', [], 'Reconnecting'
        #flush_queue
      else
        $log.warn("IRCConnection.reconnect #{@name}") { "Lost connection." }
      end

      @reconnecting = true
      Events.delete_for @channels
      Events.delete_for @users

      EM.add_timer(Bot::Conf[:core][:reconwait]) do
        $log.warn("IRCConnection.reconnect #{@name}") { "Attempting to reconnect." }
      
        @config = Bot::Conf[:servers][name]
        super @config[:address], @config[:port]
      end
    end

    # Make sure the connection is closed or closing and delete any external
    # data that wouldn't otherwise be cleaned up, including connection events.
    def destroy
      unless @disconnecting
        send_command 'QUIT'
        flush_queue
      end

      unless @caps == nil
        @caps.destroy
        @caps = nil
      end

      Events.delete_for self
    end

    # Called by EventMachine when the TCP connection is open.
    #
    # User and channel data structures are initialized here rather than
    # {IRCConnection#initialize} so that old data does not survive reconnects.
    #
    # If SSL is enabled in the configuration, begin communicating using SSL.
    #
    # Finally, start the message queue timer and send registration.
    def connection_completed
      $log.info("IRCConnection.post_init #{@name}") { "Connection established." }

      @users          = UserManager.new self
      @channels       = Channels.new self
      @registered     = false
      @reconnecting   = false
      @disconnecting  = false

      @bytes_sent     = 0
      @bytes_received = 0
      @lines_sent     = 0
      @lines_received = 0

      bind = Bot::Conf[:core][:bind]
      @client_host = bind == nil ? "" : bind

      if @config[:ssl]
        # TODO: Support more options here via the config file.
        if !@config[:ssl_cert].nil? and !@config[:ssl_key].nil?
          start_tls :private_key_file => @config[:ssl_key],
            :cert_chain_file          => @config[:ssl_cert],
            :verify_peer              => false
        else
          start_tls :verify_peer => false
        end
      end

      send_single_message
      register
    end

    # Called by EventMachine when the connection is closed.
    #
    # Cancel the message queue timer, and attempt to reconnect (if necessary).
    def unbind
      EM.cancel_timer @timer
      
      @registered = false

      return if @disconnecting or @reconnecting

      reconnect true
    end

    # Called by EventMachine when data arrives on the socket.
    #
    # Inbound data is buffered and split on line boundaries.
    #
    # @see IRCConnection#receive_line
    #
    # @param data [String]
    def receive_data data
      @buf.extract(data).each do |line|
        @lines_received += 1
        @bytes_received += line.bytesize

        receive_line line.chomp
      end
    end

    # Called by {IRCConnection#receive_data} for every comlete line that is
    # received.
    #
    # Lines are used to create new {Message} objects, which is then used to
    # dispatch the events `raw` and `msg.type`.
    #
    # If one of those events generates an exception which is not handled
    # within the dispatch call, it is caught here as a last resort.
    #
    # @param line [String]
    def receive_line line
      msg = Message.new self, line.clone

      Bot::Ignores.each do |ignore|
        break unless msg.origin

        if msg.origin.wildcard_match ignore
          $log.debug("IRCConnection.receive_line #{@name}") { "Ignoring message from #{msg.origin}" }
          return
        end
      end

      begin

        Events.dispatch :raw,     msg
        Events.dispatch msg.type, msg

      rescue Exception => e
        $log.error("IRC.receive_line") { "#{@name}: Uncaught error in message handler: #{e}" }
        $log.error("IRC.receive_line") { "#{@name}: Backtrace: #{e.backtrace}" }
      end
    end

    # Send a raw string over the IRC connection.
    #
    # This should not be called directly by scripts. It is the endpoint for
    # IRC command macros.
    #
    # Carriage returns and newlines are stripped and the message is added to
    # the outgoing queue.
    #
    # @param str [String] string to send over the socket
    # @param priority [Symbol] :slow, :fast, or :immediate
    #
    # @return [String] the string that was actually queued (after sanitization)
    def raw str, priority = :slow
      return if @disconnecting

      str.delete! "\r\n\0"
      $log.debug("IRCConnection.raw #{@name}") { "Queued: #{str}" }
      Events.dispatch(:raw_out, Message.new(self, str, true))
      
      if @config[:send_formatting] === false
        str = Bot.strip_irc_formatting str
      end

      case priority
      when :slow
        @send_queue_slow << str.freeze
      when :fast
        @send_queue_fast << str.freeze
      when :immediate
        raw_fast str
      else
        @send_queue_slow << str.freeze
      end

      str
    end

    # Send a message immediately, bypassing the queue and throttling.
    # This isn't guaranteed to send the message this instant, since it will
    # still end up in EventMachine's outgoing queue.
    #
    # This should only be called when message delivery is absolutely important,
    # such as for server PING replies.
    #
    # Carriage returns and newlines are stripped and the message is immediately
    # added to the final outgoing queue in EventMachine.
    #
    # @param str [String] string to send over the socket
    #
    # @return [String] the string that was actually sent (after sanitization)
    def raw_fast str
      return if @disconnecting

      str.delete! "\r\n\0"
      $log.debug("IRCConnection.raw_fast #{@name}") { "Sending: #{str}" }
      Events.dispatch(:raw_out, Message.new(self, str, true))

      if @config[:send_formatting] === false
        str = Bot.strip_irc_formatting str
      end

      send_data str

      str
    end


    # XXX - a lot of these need to be private
    #       figure out which and make it happen


    # Immediately send data over the socket with an appended newline.
    #
    # @param data [String]
    def send_data data
      super "#{data}\n"
        
      @lines_sent += 1
      @bytes_sent += data.bytesize + 1

      $log.debug("IRCConnection.send_data #{@name}") { data }
    end

    # Quickly flush the outgoing queue without throttling any messages. This
    # should be used with great care, as it is presently quite simple to cause
    # a bot to continuously flood itself offline until the queue is empty.
    def flush_queue
      until @send_queue_fast.empty?
        send_data @send_queue_fast.pop
      end

      until @send_queue_slow.empty?
        send_data @send_queue_slow.pop
      end
    end

    # Internal method for sending one message from the outgoing queue.
    # Throttling takes place here.
    def send_single_message
      now = Time.now.to_i
      delay = Bot::Conf[:core][:throttle]

      if not @send_queue_fast.empty?
        str = @send_queue_fast.pop
      elsif not @send_queue_slow.empty?
        str = @send_queue_slow.pop
      end

      if str
        if str.length > 512
          $log.error("IRCConnection.send_single_message #{@name}") { "Message too large: #{str}" }

          EM.add_timer(delay) do
            send_single_message
          end
        end
        
        send_data str

        if @registereed
          @history << now
          @history.shift if @history.length == 5

          if @history.length == 5 and @history[0] > now - 2
            delay = 2
            $log.info("IRCConnection.send_single_essage #{@name}") { "Throttling outgoing messages." }
          end
        end
      end

      @timer = EM.add_timer(delay) { send_single_message }
    end

    # Send all registration and pre-registration commands, such as PASS, NICK,
    # and USER.
    def register
      raw "PASS #{@config[:password]}" if @config.has_key? :password
      raw "CAP LS" if defined? MODULE_LOADED_CLIENT_CAPABILITIES

      raw "NICK #{@nick}"
      raw "USER #{@user} 0 0 :#{@realname}"
    end

    # Callback for 001 numeric.
    #
    # Once this has been called, the connection is ready for use.
    #
    # @param msg [Message] the message which triggered the callback
    def on_registered msg
      return unless msg.connection == self

      @isupport, @registered = {}, true

      raw "MODE #{@nick} +#{@config[:umodes]}" if @config.has_key? :umodes
    end

    # Callback for the nick in use numeric.
    #
    # If registration is complete, do nothing, as the bot is only trying to
    # change nicks. Whatever attempted the change can deal with this however it
    # wants.
    #
    # If this is called, attempt using the bot's alternate nick, or we append
    # underscores to the nick.
    #
    # @param msg [Message] the message which triggered the callback
    def on_nick_in_use msg
      return if @registered or msg.connection != self

      if @nick == Bot::Conf[:core][:nick]

        if Bot::Conf[:core].has_key? :altnick
          raw "NICK #{Bot::Conf[:core][:altnick]}"
        else
          raw "NICK TerminusBot"
        end

        return
      end

      @nick << "_"

      raw "NICK #{@nick}"
    end

    # Callback for NICK message.
    #
    # If the nick change is for the bot, store the new nick.
    #
    # @param msg [Messasge] the message which triggered the callback
    def on_nick msg
      return unless msg.connection == self

      if msg.me?
        @nick = msg.text
        return
      end
    end

    # Callback for 005 numeric (ISUPPORT)
    #
    # ISUPPORT contains various network configuration and behavior data. Here,
    # we parse it and store it in the connection object.
    #
    # @param msg [Message] message which triggered the callback
    def on_isupport msg
      return if msg.connection != self

      # Limit iteration to everything between the nick and ":are supported
      # by this server"
      msg.raw_arr[3...-5].each do |arg|
        key, value = arg.split('=', 2)

        @isupport[key.upcase] = value
      end

    end

    # Canonize a string using the rule specified by CASEMAPPING.
    # @param str [String] string to canonize
    # @return [String] canonized string
    def canonize str

      case support("CASEMAPPING", "rfc1459").downcase

      when "ascii"
        str.upcase

      when "rfc1459", nil
        str.upcase.tr("|{}^", "\\\\[]~")

      when "strict-rfc1459"
        str.upcase.tr("|{}", "\\\\[]")

      else
        str.upcase.tr("|{}^", "\\\\[]~")

      end

    end

    # Actually send the reply.
    #
    # If `prefix` is true, prefix each message with the triggering user's nick.
    # If replying in private, never use a prefix, and reply with NOTICE
    # instead.
    #
    # @param msg [Message] message which triggered the event to which we are
    #   replying
    # @param str [String] message to send as the reply
    # @param prefix [Boolean] if true and if msg is private, prefix message
    #   with speaker's nick
    def send_reply msg, str, prefix = true
      if str.empty?
        str = "I tried to send you an empty message. Oops!"
      end

      # TODO: Hold additional content for later sending or something.
      #       Just don't try to send it all in multiple messages without
      #       the user asking for it!
      unless msg.query?
        use_prefix = Bot::Conf[:core][:replyprefix] rescue true

        str = "#{msg.nick}: #{str}" if prefix and use_prefix

        send_privmsg msg.destination, str
      else
        send_notice msg.nick, str
      end
    end

    # Attempt to truncate a PRIVMSG or NOTICE message body in such a way that
    # the maximum amount of space possible is used. This assumes the server
    # will send a full 512 bytes to a client with exactly 1459 format.
    #
    # @param message [String] message body
    # @param destination [String] message destination
    # @param notice [Boolean] true if the message is a notice
    #
    # @return [String] truncated message
    def truncate message, destination, notice = false
      prefix_length = @nick.length +
        @user.length +
        @client_host.length +
        destination.length +
        15

      # PRIVMSG is 1 char longer than NOTICE
      prefix_length += 1 unless notice

      if (prefix_length + message.length) - 512 > 0
        return message[0..511-prefix_length]
      end

      message
    end
    
    # Check if the given string is a channel name. CHANTYPES from ISUPPORT is
    # used if available.
    #
    # @return [Boolean] true if the string appears to be a channel name
    def is_channel_name? str
      return false if str.nil? or str.include? ' ' #XXX

      return support('CHANTYPES', '#&').include? str.chr
    end

    # Retrieve ISUPPORT data.
    #
    # @param param [String] ISUPPORT value name
    # @param default [String] value to return if ISUPPORT did not specify the
    #   requested item
    #
    # @return [String] value of requested ISUPPORT item
    def support param, default = nil
      param.upcase!

      @isupport.has_key?(param) ? @isupport[param] : default
    end

    # Create a human-readable string with info about the connection.
    #
    # @return [String] human-readable connection description
    def to_s
      "#{@name} (#{@channels.length} channels)"
    end

  end

end
# vim: set tabstop=2 expandtab:
