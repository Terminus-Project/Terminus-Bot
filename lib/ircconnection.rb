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

  class IRCConnection < EventMachine::Connection
    require 'timeout'

    attr_reader :config, :name, :channels, :users, :client_host, :caps, :nick, :user, :realname

    def initialize(name)
      Bot::Connections[name] = self

      @disconnecting = false
      @reconnecting  = false
      @send_queue    = Queue.new
      @history       = []
      @isupport      = {}
      @buf           = BufferedTokenizer.new
      @client_host   = ""
      
      @caps = ClientCapabilities.new(self) if defined? MODULE_LOADED_CLIENT_CAPABILITIES

      @name = name
      @name.freeze

      @nick     = Bot::Config[:core][:nick]
      @user     = Bot::Config[:core][:user]
      @realname = Bot::Config[:core][:realname]
      @config   = Bot::Config[:servers][name]

      $log.debug("IRCConnection.initialize #{name}") { "#{@config[:address]}:#{@config[:port]} #{@nick}!#{@user}@ #{@realname}" }

      Events.create(self, :NICK,  :on_nick)
      Events.create(self, :"433", :on_nick_in_use)
      Events.create(self, :"001", :on_registered)
      Events.create(self, :"005", :on_isupport)

      Flags.add_server(name.to_s)

      timeout = @config[:timeout] rescue 0
      set_comm_inactivity_timeout(timeout)

      $log.debug("IRCConnection.initialize #{name}") { "Done preparing connection." }
    end


    def disconnect(quit_message = "Terminus-Bot: Terminating")
      raw "QUIT :#{quit_message}"

      @disconnecting = true

      flush_queue
    end

    def reconnect(lost_connection = false)
      unless lost_connection
        raw "QUIT :Reconnecting"
        flush_queue
      else
        $log.warn("IRCConnection.reconnect #{@name}") { "Lost connection." }
      end

      @reconnecting = true

      EM.add_timer(Bot::Config[:core][:reconwait]) do
        $log.warn("IRCConnection.reconnect #{@name}") { "Attempting to reconnect." }

        super(@config[:address], @config[:port])
      end
    end

    def destroy
      unless @disconnecting
        raw "QUIT"
        flush_queue
      end

      unless @caps == nil
        @caps.destroy
        @caps = nil
      end

      Events.delete_for(self)
    end


    def connection_completed
      $log.info("IRCConnection.post_init #{@name}") { "Connection established." }

      @users      = UserManager.new(self)
      @channels   = Channels.new(self)
      @registered = false

      @disconnecting, @reconnecting = false, false

      bind = Bot::Config[:core][:bind]
      @client_host = bind == nil ? "" : bind

      if @config[:ssl]
        # TODO: Support more options here via the config file.
        start_tls(:verify_peer => false)
      end

      send_single_message
      register
    end

    def unbind
      return if @disconnecting or @reconnecting

      EM.cancel_timer(@timer)

      reconnect(true)
    end

    def receive_data(data)
      @buf.extract(data).each do |line|
        receive_line line.chomp
      end
    end

    def receive_line(line)
      msg = Message.new(self, line.clone)

      Bot::Ignores.each do |ignore|
        if msg.origin.wildcard_match(ignore)
          $log.debug("IRCConnection.receive_line #{@name}") { "Ignoring message from #{msg.origin}" }
          return
        end
      end

      begin

        Events.dispatch(:raw,     msg)
        Events.dispatch(msg.type, msg)

      rescue Exception => e
        $log.error("IRC.receive_line") { "#{@name}: Uncaught error in message handler: #{e}" }
        $log.error("IRC.receive_line") { "#{@name}: Backtrace: #{e.backtrace}" }
      end
    end


    def raw(str)
      return if @disconnecting

      str.delete! "\r\n"
      $log.debug("IRCConnection.raw #{@name}") { "Queued: #{str}" }
      Events.dispatch(:raw_out, Message.new(self, str, true))

      @send_queue << str.freeze

      str
    end

    # Send a message immediately, bypassing the queue and throttling.
    # This isn't guaranteed to send the message this instant, since it will
    # still end up in EventMachine's outgoing queue.
    def raw_fast(str)
      return if @disconnecting

      str.delete! "\r\n"
      $log.debug("IRCConnection.raw_fast #{@name}") { "Sending: #{str}" }
      Events.dispatch(:raw_out, Message.new(self, str, true))

      send_data(str)

      str
    end

    def send_data(data)
      super "#{data}\n"

      $log.debug("IRCConnection.send_data #{@name}") { data }
    end

    def flush_queue
      until @send_queue.empty?
        send_data @send_queue.pop
      end
    end

    def send_single_message
      now = Time.now.to_i
      delay = Bot::Config[:core][:throttle]

      unless @send_queue.empty? or @reconnecting
        str = @send_queue.pop

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


    def register
      raw "PASS #{@config[:password]}" if @config.has_key? :password
      raw "CAP LS" if defined? MODULE_LOADED_CLIENT_CAPABILITIES

      raw "NICK #{@nick}"
      raw "USER #{@user} 0 0 :#{@realname}"
    end


    def on_registered(msg)
      return unless msg.connection == self

      @isupport, @registered = {}, true
    end

    def on_nick_in_use(msg)
      return if @registered or msg.connection != self

      if @nick == Bot::Config[:core][:nick]

        if Bot::Config[:core].has_key? :altnick
          raw "NICK #{Bot::Config[:core][:altnick]}"
        else
          raw "NICK TerminusBot"
        end

        return
      end

      @nick << "_"

      raw "NICK #{@nick}"
    end

    def on_nick(msg)
      return unless msg.connection == self

      if msg.me?
        @nick = msg.text
        return
      end
    end

    def on_isupport(msg)
      return if msg.connection != self

      # Limit iteration to everything between the nick and ":are supported
      # by this server"
      msg.raw_arr[3...-5].each do |arg|
        key, value = arg.split('=', 2)

        @isupport[key.upcase] = value
      end

    end


    # string canonizer, using the rule specified by CASEMAPPING
    def canonize(str)

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

    # retrieve ISUPPORT values or default to a value we don't have
    def support(param, default = nil)
      param.upcase!

      @isupport.has_key?(param) ? @isupport[param] : default
    end

    def to_s
      "#{@name} (#{@channels.length} channels)"
    end

  end

end
