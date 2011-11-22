
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
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

    attr_reader :name, :socket, :channels, :host, :port, :read_thread, :users

    def initialize(name, host, port = 6667, bind = nil, password = nil,
                   nick = "Terminus-Bot", user = "Terminus",
                   realname = "http://terminus-bot.net/")

      $bot.events.create(self, "JOIN",  :on_join)
      $bot.events.create(self, "PART",  :on_part)
      $bot.events.create(self, "KICK",  :on_kick)
      $bot.events.create(self, "MODE",  :on_mode)
      $bot.events.create(self, "324",   :on_324)

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

      @send_queue = Queue.new
      @send_thread = send_thread

      start_connection(host, port, bind, password, nick, user, realname)

      @read_thread = read_thread

      return self
    end

    def start_connection(host, port, bind, password, nick, user, realname)

      # Do all this here since this data is only relevant to the
      # current connection.
      #
      # TODO: We may want to keep some of this (such as logged in
      # users) between sessions.

      $log.debug("Connection.start_connection") { "Starting connection: #{host}:#{port}" }

      @send_queue.clear
      @users = Users.new(self)
      @channels = Hash.new
      @socket = TCPSocket.open(host, port, bind)

      $log.debug("Connection.start_connection") { "Connection to #{host}:#{port} established. Sending registration." }

      raw "PASS " + password unless password == nil

      raw "NICK " + nick
      raw "USER #{user} 0 0 :" + realname

      $log.debug("Connection.start_connection") { "Registration sent to #{host}:#{port}." }
    end

    def read_thread
      if @read_thread != nil
        if @read_thread.alive?
          @read_thread.kill
        end
      end

      return Thread.new do
        while true

          until @socket.eof?
            inbuf = @socket.gets.chomp

            $log.debug("Bot.read_thread") { "Received: #{inbuf}" }

            Thread.new do
              begin
                IRC::Message.new(self, inbuf)
              rescue => e
                $log.error("Bot.send_thread") { "Uncaught rror in message handler thread: #{e}" }
              end
            end

          end

          $log.warn("Bot.send_thread") { "Disconnected. Waiting to reconnect..." }

          sleep Float($bot.config['core']['reconwait'])

          start_connection(@host, @port, @bind, @password, @nick, @user, @realname)
        end

        $log.error("Bot.read_thread") { "Thread ended!" }
      end
    end

    def send_thread
      if @send_thread != nil
        if @send_thread.alive?
          @send_thread.kill
        end
      end

      return Thread.new do
        while true
          msg = @send_queue.pop

          throw "Message Too Large" if msg.length > 512

          @socket.puts(msg)

          $log.debug("Bot.send_thread") { "Sent: #{msg}" }
          $log.debug("Bot.send_thread") { "Queue size: #{@send_queue.length}" }

          $log.debug("Bot.send_thread") { "Sleeping for #{$bot.config['core']['throttle']} seconds" }

          sleep Float($bot.config['core']['throttle'])
        end

        $log.error("Bot.send_thread") { "Thread ended!" }
      end
    end

    def raw(str)
      $log.debug("Bot.send") { "Queued #{str}" }
      @send_queue.push(str)
      return str
    end

    def send_notice(arget, str)
      if str.length > 400
        str = str[0..400] + "..."
      end

      raw("NOTICE #{target} :#{str}")
    end

    def disconnect(quit_message = "Terminus-Bot: Terminating")
      raw "QUIT :" + quit_message
    end

    # WHO reply
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

    # modes sent on join"
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

    def initialize(connection, str)

      @connection = connection

      arr = str.split
      
      @raw_arr = arr
      @raw = str

      if str[0] == ":"

        @origin = arr[0][1..arr[0].length-1]
        @type = arr[1]
        @destination = arr[2]

        begin
          @nick = @origin.split("!")[0]
        rescue
          @nick = ""
        end

        if str =~ /\A:[^:]+:(.+)\Z/
          @text = $1
        else
          @text = ""
        end

      else

        @type = arr[0]
        @origin = ""
        @destination = ""

        if str =~ /.+:(.+)\Z/
          @text = $1
        else
          @text = ""
        end
      end

      $bot.events.run(:raw, self)
      $bot.events.run(@type, self)
    end

    def reply(str, prefix = true)
      if str.kind_of? Array
        str.each do |this_str|
          send_reply(this_str, prefix)
        end
      else
        send_reply(str, prefix)
      end
    end

    def send_reply(str, prefix)
      if str.empty?
        str = "I tried to send you an empty message. Oops!"
      end

      if str.length > 400
        str = str[0..400] + "..."
      end

      if @destination.start_with? "#"
        @connection.raw("PRIVMSG #{@destination} :#{prefix ? @nick + ": " : ""}#{str}")
      else
        @connection.raw("NOTICE #{@nick} :#{str}")
      end
    end

    def raw(*args)
      @connection.raw(*args)
    end

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

    def initialize(name)
      @name = name
      @topic = ""
      @key = ""
      @modes = Array.new
      @users = Array.new
    end

    def mode_change(modes)
      $log.debug("Channel.mode_change") { "Changing modes for #{@name}: #{modes}" }

      plus = true

      modes.each_char do |mode|

        if mode == "+"
          plus = true

        elsif mode == "-"
          plus = false

        elsif mode == " "
          # We're not handling modes with args right now.
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

    def topic(str)
      @topic = str
    end

    def join(user)
      return if @users.select {|u| u.nick == user.nick}.length > 0

      $log.debug("Channel.join") { "#{user.nick} joined #{@name}" }
      @users << user
    end

    def part(nick)
      $log.debug("Channel.part") { "#{nick} parted #{@name}" }
      @users.delete_if {|u| u.nick == nick}
    end

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
