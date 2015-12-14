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

# TODO: Refactor to new code style

@@log_dir = "var/terminus-bot/chanlog/"

register 'Logs channel activity to disk.'

@@loggers = {}

FileUtils.mkdir_p @@log_dir

event :em_started do
  # If we're being loaded on a bot that's already running, we're not going
  # to see the JOIN events we need to start the loggers. So we have to do
  # it the hard way, just in case.

  Bot::Connections.each_value do |connection|
    connection.channels.each_key do |channel|
      new_logger connection.name, channel
    end
  end
end

helpers do

  def die
    # Close all our loggers.
    @@loggers.each_value do |c|
      c.each_value do |l|
        l.close
      end
    end
  end


  # Logger stuff

  def log_msg network, channel, type, speaker, str = ""
    $log.debug("chanlog.log_msg") { "#{network} #{channel} #{type} #{speaker} #{str}" }

    new_logger network, channel

    @@loggers[network][channel].info(type) { "#{speaker}\t#{str}" }
  end

  def new_logger network, channel
    @@loggers[network] ||= {}

    if @@loggers[network].key? channel
      # We already have a logger for this channel.
      return
    end

    @@loggers[network][channel] = Logger.new "#{@@log_dir}#{network}.#{channel}.log"

    @@loggers[network][channel].formatter = proc do |_severity, datetime, progname, msg|
      "#{datetime}\t#{progname}\t#{msg}\n"
    end

    @@loggers[network][channel].datetime_format = "%Y-%m-%d %H:%M:%S %z"

    $log.debug("chanlog.new_logger") { "#{network} #{channel}" }
  end

  def close_logger network, channel
    @@loggers[network][channel].close
    @@loggers[network].delete channel

    $log.debug("chanlog.close_logger") { "#{network} #{channel}" }
  end

end

# Event callbacks

event :PRIVMSG, :raw_out do
  next if query? or not @msg.type == :PRIVMSG

  if @msg.text =~ /\01ACTION (.+)\01/
    log_msg @connection.name, @msg.destination, "ACTION", @msg.nick, Bot.strip_irc_formatting($1)
  elsif not @msg.text =~ /\01.+\01/
    log_msg @connection.name, @msg.destination, "PRIVMSG", @msg.nick, @msg.stripped
  end
end

event :NOTICE do
  next if query?

  unless @msg.text =~ /\01.+\01/
    log_msg @connection.name, @msg.destination, "NOTICE", @msg.nick, @msg.stripped
  end
end

event :KICK do
  log_msg @connection.name, @msg.destination, "KICK", @msg.nick, "#{@msg.raw_arr[3]} (#{@msg.stripped})"

  # If we're the ones kicked, close the logger.
  if @msg.raw_arr[3] == @connection.nick
    close_logger @connection.name, @msg.destination
  end
end

event :PART do
  log_msg @connection.name, @msg.destination, "PART", @msg.nick, @msg.stripped

  # We parted, apparently. Stop logging.
  if @msg.me?
    close_logger @msg.connection.name, @msg.destination
  end
end

event :JOIN do
  # We joined. Better get ready to log!
  if @msg.me?
    new_logger @msg.connection.name, @msg.destination
  end

  log_msg @msg.connection.name, @msg.destination, "JOIN", @msg.nick
end

event :QUIT_CHANNEL do
  chan = @data[:channel]

  log_msg @connection.name, chan.name, "QUIT", @msg.nick, @msg.stripped
end

event :TOPIC do
  log_msg @connection.name, @msg.destination, "TOPIC", @msg.nick, @msg.stripped
end

event :NICK do
  @connection.channels.each_value do |chan|
    if chan.get_user @msg.nick or chan.get_user @msg.text
      log_msg @connection.name, chan.name, "NICK", @msg.nick, @msg.text
    end
  end
end

event :MODE do
  log_msg @connection.name, @msg.destination, "MODE", @msg.nick, @msg.raw_arr[3..@msg.raw_arr.length-1].join(" ")
end

# vim: set tabstop=2 expandtab:
