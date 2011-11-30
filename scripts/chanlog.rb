
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


def initialize
  register_script("Logs channel activity to disk.")

  register_event("PRIVMSG", :on_privmsg)

  register_event("NOTICE",  :on_notice)
  register_event("TOPIC",   :on_topic)

  register_event("KICK",    :on_kick)
  register_event("PART",    :on_part)
  register_event("JOIN",    :on_join)
  register_event("QUIT",    :on_quit)

  register_event("NICK",    :on_nick)
  register_event("MODE",    :on_mode)


  unless Dir.exists? "var/chanlog/"
    Dir.mkdir("var/chanlog/")
  end

  @loggers = Hash.new

  # If we're being loaded on a bot that's already running, we're not going
  # to see the JOIN events we need to start the loggers. So we have to do
  # it the hard way, just in case.

  $bot.connections.each do |name, connection|
    connection.channels.each_key do |channel|
      new_logger(connection.name, channel)
    end
  end
end

def die
  # Close all our loggers.
  @loggers.each_value do |c|
    c.each_value do |l|
      l.close
    end
  end

  unregister_script
  unregister_events
end


# Logger stuff

def log_msg(network, channel, type, speaker, str = "")
  $log.debug("chanlog.log_msg") { "#{network} #{channel} #{type} #{speaker} #{str}" }
  @loggers[network][channel].info(type) { "#{speaker}\t#{str}" }
end

def new_logger(network, channel)
  unless @loggers.has_key? network
    @loggers[network] = Hash.new
  end

  unless @loggers[network].has_key? channel
    @loggers[network][channel] = Logger.new("var/chanlog/#{network}.#{channel}.log", File::APPEND)
  else
    # We already have a logger for this channel.
    return
  end

  @loggers[network][channel].formatter = proc do |severity, datetime, progname, msg|
    "#{datetime}\t#{progname}\t#{msg}\n"
  end

  @loggers[network][channel].datetime_format = "%Y-%m-%d %H:%M:%S %z"

  $log.debug("chanlog.new_logger") { "#{network} #{channel}" }
end

def close_logger(network, channel)
  @loggers[network][channel].close
  @loggers[network].delete(channel)

  $log.debug("chanlog.close_logger") { "#{network} #{channel}" }
end


# Event callbacks

def on_privmsg(msg)
  return if msg.private?

  if msg.text =~ /\01ACTION (.+)\01/
    log_msg(msg.connection.name, msg.destination, "ACTION", msg.nick, $1)
  elsif not msg.text =~ /\01.+\01/
    log_msg(msg.connection.name, msg.destination, "PRIVMSG", msg.nick, msg.text)
  end
end

def on_notice(msg)
  return if msg.private?

  unless msg.text =~ /\01.+\01/
    log_msg(msg.connection.name, msg.destination, "NOTICE", msg.nick, msg.text)
  end
end

def on_kick(msg)
  log_msg(msg.connection.name, msg.destination, "KICK", msg.nick, msg.raw_arr[3] + "(#{msg.text})")

  # If we're the ones kicked, close the logger.
  if msg.raw_arr[3] == msg.connection.nick
    close_logger(msg.connection.name, msg.destination)
  end
end

def on_part(msg)
  log_msg(msg.connection.name, msg.destination, "PART", msg.nick)

  # We parted, apparently. Stop logging.
  if msg.me?
    closer_logger(msg.connection.name, msg.destination)
  end
end

def on_join(msg)
  # We joined. Better get ready to log!
  if msg.me?
    new_logger(msg.connection.name, msg.destination)
  end

  log_msg(msg.connection.name, msg.destination, "JOIN", msg.nick)
end

def on_quit(msg)
  msg.connection.channels.each_value do |chan|
    if chan.get_user(msg.nick)
      log_msg(msg.connection.name, chan.name, "QUIT", msg.nick, msg.text)
    end
  end
end

def on_topic(msg)
  log_msg(msg.connection.name, msg.destination, "TOPIC", msg.nick, msg.text)
end

def on_nick(msg)
  msg.connection.channels.each_value do |chan|
    if chan.get_user(msg.nick) or chan.get_user(msg.text)
      log_msg(msg.connection.name, chan.name, "NICK", msg.nick, msg.text)
    end
  end
end

def on_mode(msg)
  log_msg(msg.connection.name, msg.destination, "MODE", msg.nick, msg.raw_arr[3..msg.raw_arr.length-1].join(" "))
end
