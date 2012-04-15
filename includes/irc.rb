
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
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

class IRC_Connection < EventMachine::Connection

  require 'socket'
  require 'timeout'

  attr_reader :name, :channels, :conf, :bind,
   :users, :client_host, :nick, :user, :realname, :isupport

  # Create a new connection, then kick things off.
  def initialize(name, conf, bind = nil, nick = "Terminus-Bot",
                 user = "Terminus", realname = "http://terminus-bot.net/")

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

    $bot.events.create(self, "NICK",  :on_nick)
    $bot.events.create(self, "433",   :on_nick_in_use)

    $bot.events.create(self, "001",   :on_registered)
    $bot.events.create(self, "005",   :on_isupport)

    @name = name
    @nick = nick
    @user = user
    @realname = realname

    @name.freeze

    @bind = bind

    @conf = conf

    @isupport = Hash.new

    @registered, @reconnecting = false, false

    # We queue up messages here
    @send_queue = Queue.new

    # Keep the timestamps for our last few messages for smart throttling.
    @history = []

    send_single_message

    # TODO: Okay to probe $bot's inner structures?
    $bot.connections[name] = self
    $bot.flags.add_server(name)
  end

  # Called after the socket is opened.
  def post_init
    $log.debug("IRC.post_init") { "Starting connection: #{@host}:#{@port}" }

    @users = Users.new(self)
    @channels = Hash.new
    @registered = false

    @client_host = (bind == nil ? "" : bind)

    if @conf["ssl"]
      # TODO: Support more options here via the config file.
      start_tls(:verify_peer => false)
    end

    register
  end

  def send_single_message
    now = Time.now.to_i

    delay = $bot.config['core']['throttle']

    unless @send_queue.empty? or @reconnecting
      msg = @send_queue.pop
      throw "Message Too Large" if msg.length > 512

      send_data msg
      @history << now
      @history.shift if @history.length == 5

      unless @history.empty?
        if @history[0] > now - 2
          delay = 2
          $log.info("irc.send_single_Message") { "Outgoing flood detected. Throttling (#{delay})." }
        end
      end
    end
    
    EM.add_timer(delay) { send_single_message }
  end

  # TODO: Make room for SASL.
  def register
    raw "PASS #{@conf["password"]}" if @conf.has_key? "password"

    raw "NICK #{@nick}"
    raw "USER #{@user} 0 0 :#{@realname}"
  end

  def send_data(data)
    super("#{data}\n")

    $bot.lines_out += 1
    $bot.bytes_out += data.length + 2

    $log.debug("IRC.send_data") { "Sent: #{data}" }
  end

  def receive_data(data)
    (@buf ||= BufferedTokenizer.new).extract(data).each do |line|
      $bot.lines_in += 1
      $bot.bytes_in += line.length

      receive_line line.chomp
    end
  end

  def receive_line(line)
    msg = Message.new(self, line.clone)

    $bot.ignores.each do |ignore|
      if msg.origin.wildcard_match(ignore)
        $log.debug("IRC.receive_line") { "Ignoring message from #{msg.origin}" }
        return
      end
    end

    begin

      Timeout::timeout($bot.config['core']['timeout'].to_f) do
        $bot.events.run(:raw, msg)

        $bot.events.run(msg.type, msg)  # The most important line in this file!
                                        # Also the reason we can't use symbols for
                                        # most event names. :-(
      end

    rescue => e
      $log.error("IRC.receive_line") { "#{@name}: Uncaught error in message handler: #{e}" }
      $log.error("IRC.receive_line") { "#{@name}: Backtrace: #{e.backtrace}" }
    end

  end

  # Called when we lose our connection.
  def unbind
    return if @disconnecting or @reconnecting

    reconnect
  end

  # Add an unedited string to the outgoing queue for later sending.
  def raw(str)
    return if @disconnecting

    str.delete! "\r\n"

    $log.debug("IRC.raw") { "Queued #{str}" }

    $bot.events.run(:raw_out, Message.new(self, str, true))

    @send_queue.push(str)
    
    str
  end

  # Send a QUIT with optional messsage. Handling the closing socket
  # is up to other things; this just adds the QUIT to the queue and
  # returns.
  def disconnect(quit_message = "Terminus-Bot: Terminating")
    raw "QUIT :#{quit_message}"

    @disconnecting = true

    close
  end

  # Empty the queue and then reconnect.
  def reconnect
    return if @disconnecting

    @reconnecting, @disconnecting = true, true
    raw "QUIT :Reconnecting"

    @send_queue.length.times do
      send_data @send_queue.pop
    end

    # Grab server config again in case we rehashed.
    @conf = $bot.config["servers"][@name]

    EM.add_timer(5) {
      @disconnecting = false
      super(@conf["address"], @conf["port"])
      register
    }
  end

  # Clean up the connection.
  def close
    @send_queue.length.times do
      send_data @send_queue.pop
    end

    close_connection_after_writing
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
      @channels[msg.raw_arr[3]] = Channel.new(msg.raw_arr[3], self)
    end

    @channels[msg.raw_arr[3]].join(ChannelUser.new(canonize(msg.raw_arr[7]),
                                                   msg.raw_arr[4],
                                                   msg.raw_arr[5]))

    @channels[msg.raw_arr[3]].who_modes(msg.raw_arr[7], msg.raw_arr[8])
  end

  def on_join(msg)
    return if msg.connection != self

    unless @channels.has_key? msg.destination
      @channels[msg.destination] = Channel.new(msg.destination, self)
      $bot.flags.add_channel(@name, msg.destination)
    end

    if msg.me?
      msg.raw("MODE #{msg.destination}")
      msg.raw("WHO #{msg.destination}")
    end

    @channels[msg.destination].join(ChannelUser.new(msg.nick_canon, msg.user, msg.host))
  end

  def on_part(msg)
    return if msg.connection != self

    return unless @channels.has_key? msg.destination

    if msg.me?
      @channels.delete(msg.destination)
      return
    end

    @channels[msg.destination].part(msg.nick_canon)
  end

  def on_kick(msg)
    return if msg.connection != self

    return unless @channels.has_key? msg.destination

    @channels[msg.destination].part(canonize msg.raw_arr[3])
  end

  def on_mode(msg)
    return if msg.connection != self

    return unless @channels.has_key? msg.destination

    @channels[msg.destination].mode_change(msg.raw_arr[3..-1])
  end

  # modes sent on join
  def on_324(msg)
    return if msg.connection != self

    return unless @channels.has_key? msg.raw_arr[3]

    @channels[msg.raw_arr[3]].mode_change(msg.raw_arr[4..-1])
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

  def on_registered(msg)
    return if msg.connection != self

    @isupport = Hash.new

    @registered = true
  end

  def on_nick(msg)
    return unless msg.me? and msg.connection == self

    @nick = msg.text
  end

  # We tried to switch to a nick that's in use.
  def on_nick_in_use(msg)

    # If we're done connecting, then this is happening because
    # someone tried to have the bot change nicks to something taken.
    # No sense in spinning around on it — just keep our current nick.
    
    return if @registered or msg.connection != self

    if @nick == $bot.config['core']['nick']

      if $bot.config['core'].has_key? 'altnick'
        raw "NICK #{$bot.config['core']['altnick']}"
      else
        raw "NICK TerminusBot"
      end

      return
    end

    @nick << "_"

    raw "NICK #{@nick}"
  end

  def on_isupport(msg)

    # Limit iteration to everything between the nick and ":are supported
    # by this server"
    msg.raw_arr[3...-5].each do |arg|
      key, value = arg.split('=', 2)

      @isupport[key.upcase] = value
    end

  end

  # TODO: Re-implement this as String#irccasecmp or something. Doing it this
  # way seems really incorrect.
  #
  # nickname canonizer, using the rule specified by CASEMAPPING
  def canonize(nick)
 
    # TODO: do this without such an ugly case statement :(

    case support("CASEMAPPING").downcase

      when "ascii"
        nick.upcase

      when "rfc1459", nil
        nick.upcase.tr("|{}^", "\\\\[]~")   

      when "strict-rfc1459"
        nick.upcase.tr("|{}", "\\\\[]")

      else
        nick

    end
  
  end

  # retrieve ISUPPORT values or default to a value we don't have
  def support(param, default = nil)
    param.upcase!

    return default unless @isupport.has_key? param
    
    @isupport[param]
  end

  def to_s
    "#{@name} (#{@channels.length} channels)"
  end
end
