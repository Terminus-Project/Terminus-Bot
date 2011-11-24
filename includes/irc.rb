
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

    attr_reader :name, :socket, :channels, :host, :port, :read_thread, :send_thread,
    :users, :client_host, :nick, :user, :realname

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

      if msg.me?
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
end
