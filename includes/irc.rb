
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
  class Connection

    attr_reader :name, :socket, :channels, :host, :port, :read_thread, :users,
      :client_host, :nick, :user, :realname

    # Create a new connection, then kick things off.
    def initialize(name, host, port = 6667, bind = nil, password = nil,
                   nick = "Terminus-Bot", user = "Terminus",
                   realname = "http://terminus-bot.net/")

      # Register ALL the events!

      $bot.events.create(self, "JOIN",  :on_join)
      $bot.events.create(self, "PART",  :on_part)
      $bot.events.create(self, "KICK",  :on_kick)
      $bot.events.create(self, "MODE",  :on_mode)
      $bot.events.create(self, "324",   :on_324)

      $bot.events.create(self, "396",   :on_396) # hidden host

      $bot.events.create(self, "TOPIC", :on_topic)
      $bot.events.create(self, "332",   :on_332) # topic on join

      $bot.events.create(self, "352",   :on_352) # who reply
      $bot.events.create(self, "NAMES", :on_names)

      @name = name
      @host = host
      @port = port
      @bind = bind
      @nick = nick
      @user = user
      @realname = realname

      @client_host = bind

      # We queue up messages here
      @send_queue = Queue.new
      # then send them with this thread.
      @send_thread = send_thread

      # Connect!
      start_connection(host, port, bind, password, nick, user, realname)

      # Start a thread to read from the socket.
      @read_thread = read_thread

      # Return self so Bot can add us to @connections.
      return self
    end

    # Connect to IRC.
    def start_connection(host, port, bind, password, nick, user, realname)

      # Do all this here since this data is only relevant to the
      # current connection.
      #
      # TODO: We may want to keep some of this (such as logged in
      # users) between sessions.

      $log.debug("Connection.start_connection") { "Starting connection: #{host}:#{port}" }

      @send_queue.clear # Clear this, just in case we're reconnecting.
      @users = Users.new(self)
      @channels = Hash.new

      # Actually connect.
      @socket = TCPSocket.open(host, port, bind)

      $log.debug("Connection.start_connection") { "Connection to #{host}:#{port} established. Sending registration." }

      raw "PASS " + password unless password == nil

      raw "NICK " + nick
      raw "USER #{user} 0 0 :" + realname

      $log.debug("Connection.start_connection") { "Registration sent to #{host}:#{port}." }
    end

    # Read from our socket. This fires off the message parser,
    # which then fires events.
    def read_thread
      if @read_thread != nil
        if @read_thread.alive?
          @read_thread.kill
        end
      end

      return Thread.new do
        while true

          begin

            until @socket.eof?
              inbuf = @socket.gets.chomp

              $log.debug("IRC.read_thread") { "Received: #{inbuf}" }

              # This is so bad.
              # TODO: Don't spawn a new thread for every single message.
              #       One option: the old Terminus-Bot used a thread pool
              #       (5 workers, typically) and let those take messages from
              #       a queue. That seemed to work well for large loads.
              Thread.new do

                begin
                  # The Message object will fire the actual events.
                  IRC::Message.new(self, inbuf)

                rescue => e
                  $log.error("IRC.read_thread") { "Uncaught error in message handler thread: #{e}" }

                end

              end

            end

          rescue => e
            $log.error("IRC.read_thread") { "Got error on socket fpr #{@name}: #{e}" }
          end

          $log.warn("IRC.read_thread") { "Disconnected. Waiting to reconnect..." }

          sleep Float($bot.config['core']['reconwait'])

          start_connection(@host, @port, @bind, @password, @nick, @user, @realname)
        end

        $log.error("IRC.read_thread") { "Thread ended!" }
      end
    end

    # Periodically pops messages from our outgoing queue and sends them on our socket.
    def send_thread
      if @send_thread != nil
        if @send_thread.alive?
          @send_thread.kill
        end
      end

      return Thread.new do
        while true
          msg = @send_queue.pop

          # This should probably never get called, since our reply function
          # truncates messages.
          throw "Message Too Large" if msg.length > 512

          # TODO: Hold messages for later delivery if our socket is dead.
          @socket.puts(msg)

          $log.debug("IRC.send_thread") { "Sent: #{msg}" }
          $log.debug("IRC.send_thread") { "Queue size: #{@send_queue.length}" }

          $log.debug("IRC.send_thread") { "Sleeping for #{$bot.config['core']['throttle']} seconds" }

          # If we just blast through our queue at full speed, we won't even
          # make it past joining channels before being killed for flooding!
          sleep Float($bot.config['core']['throttle'])
        end

        $log.error("IRC.send_thread") { "Thread ended!" }
      end
    end

    # Add an unedited string to the outgoing queue for later sending.
    def raw(str)
      $log.debug("Bot.send") { "Queued #{str}" }
      @send_queue.push(str)
      return str
    end

    # Send a QUIT with optional messsage. Handling the closing socket
    # is up to other things; this just adds the QUIT to the queue and
    # returns.
    def disconnect(quit_message = "Terminus-Bot: Terminating")
      raw "QUIT :" + quit_message
    end

    # hidden host
    def on_396(msg)
      return if msg.connection != self

      @client_host = msg.raw_arr[3]
    end

    # WHO reply handler.
    def on_352(msg)
      return if msg.connection != self

      unless @channels.has_key? msg.raw_arr[3]
        @channels[msg.raw_arr[3]] = Channel.new(msg.raw_arr[3])
      end

      @channels[msg.raw_arr[3]].join(ChannelUser.new(msg.raw_arr[7],
                                                     msg.raw_arr[4],
                                                     msg.raw_arr[5]))
    end

    def on_join(msg)
      return if msg.connection != self

      unless @channels.has_key? msg.text
        @channels[msg.text] = Channel.new(msg.text)
      end

      msg.origin =~ /(.+)!(.+)@(.+)/

      if $1 == $bot.config['core']['nick']
        msg.raw('MODE ' + msg.text)
        msg.raw('WHO ' + msg.text)
      end

      @channels[msg.text].join(ChannelUser.new($1, $2, $3))
    end

    def on_part(msg)
      return if msg.connection != self

      return unless @channels.has_key? msg.destination

      @channels[msg.destination].part(msg.nick)
    end

    def on_kick(msg)
      return if msg.connection != self

      return unless @channels.has_key? msg.destination

      @channels[msg.destination].part(msg.raw_arr[3])
    end

    def on_mode(msg)
      return if msg.connection != self

      return unless @channels.has_key? msg.destination

      @channels[msg.destination].mode_change(msg.raw_arr[3])
    end

    # modes sent on join
    def on_324(msg)
      return if msg.connection != self

      return unless @channels.has_key? msg.raw_arr[3]

      @channels[msg.raw_arr[3]].mode_change(msg.raw_arr[4])
    end

    
    def on_topic(msg)
      return if msg.connection != self

      return unless @channels.has_key? msg.destination

      @channels[msg.destination].topic(msg.text)
    end
    
    # topic sent on join
    def on_332(msg)
      return if msg.connection != self

      return unless @channels.has_key? msg.raw_arr[3]

      @channels[msg.raw_arr[3]].topic(msg.text)
    end

    def to_s
      return "#{@name} (#{@channels.length} channels)"
    end

  end

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


  ChannelUser = Struct.new(:nick, :user, :host)

  class Channel

    attr_reader :name, :topic, :modes, :key, :users

    # Create the channel object. Since all we know when we join is the name,
    # that's all we're going to store here.
    def initialize(name)
      @name = name
      @topic = ""
      @key = ""
      @modes = Array.new
      @users = Array.new
    end

    # Parse mode changes for the channel. The modes are extracted elsewhere
    # and sent here.
    def mode_change(modes)
      $log.debug("Channel.mode_change") { "Changing modes for #{@name}: #{modes}" }

      plus = true

      # TODO: Handle modes with args (bans, ops, etc.) correctly.
      #       More data structures will be necessary to store that
      #       data. If we're going to parse bans and such, we'll
      #       also need to request a ban list on JOIN, and also
      #       parse the modes that can have such lists from the 003
      #       message from the server. This was done in the old Terminus-Bot
      #       but hasn't been ported yet.
      modes.each_char do |mode|

        if mode == "+"
          plus = true

        elsif mode == "-"
          plus = false

        elsif mode == " "
          return

        else
          if plus
            @modes << mode
          else
            @modes.delete(mode)
          end

        end
      end
    end

    # Store the topic.
    def topic(str)
      @topic = str
    end

    # Add a user to our channel's user list.
    def join(user)
      return if @users.select {|u| u.nick == user.nick}.length > 0

      $log.debug("Channel.join") { "#{user.nick} joined #{@name}" }
      @users << user
    end

    # Remove a user from our channel's user list.
    def part(nick)
      $log.debug("Channel.part") { "#{nick} parted #{@name}" }
      @users.delete_if {|u| u.nick == nick}
    end

    # Retrieve the channel user object for the named user, or return nil
    # if none exists.
    def get_user(nick)
      results = @users.select {|u| u.nick == nick}

      if results.length == 0
        return nil
      else
        return results[0]
      end

    end

  end

end
