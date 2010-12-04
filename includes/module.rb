
#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

class Module

  attr_reader :name, :version, :description

  # Send a message to a channel or user.
  # $bot.param [String] destination The user or channel to which the message will be sent
  # $bot.param [String] message The message to send.
  # $bot.example Say "hi!" to channel #terminus-bot
  #   sendPrivmsg("#terminus-bot", "Hi!")
  # $bot.example Greet a user in private.
  #   sendPrivmsg("Kabaka", "Hello, Kabaka!")
  def sendPrivmsg(destination, message)
    $bot.connection.sendRaw("PRIVMSG #{destination} :#{message}")
  end

  # Send a notice to a channel or user (or whatever else the server permits).
  # $bot.param [String] destination The user or channel to which the message will be sent
  # $bot.param [String] message The message to send.
  # $bot.example Say "hi!" to channel #terminus-bot
  #   sendNotice("#terminus-bot", "Hi!")
  # $bot.example Greet a user in private.
  #   sendNotice("Kabaka", "Hello, Kabaka!")
  def sendNotice(destination, message)
    $bot.connection.sendRaw("NOTICE #{destination} :#{message}")
  end

  # Send a mode change to the server with optional parameters.
  # $bot.param [String] target The target for the mode change. This will be a channel or user (if a user, it will probably need to be the bot).
  # $bot.param [String] mode The mode to send, such as +v if the target is a channel.
  # $bot.param [String] parameters Optional parameters for the mode change. This is for things like voice targets if your mode is +v and target is a channel.
  def sendMode(target, mode, parameters = "")
    $bot.connection.sendRaw("MODE #{target} #{mode}#{" #{parameters}" unless parameters.empty?}")
  end

  # Send a CTCP request. This is the same as a PRIVMSG, but wrapped in
  # the CTCP markers (character code 1).
  # $bot.param [String] destination The user or channel to which this should be sent. CTCPs should generally be sent to a user!
  # $bot.param [String] message The contents of the CTCP request, such as VERSION.
  def sendCTCP(destination, message)
    $bot.connection.sendRaw("PRIVMSG #{destination} :#{1.chr}#{message}#{1.chr}")
  end

  # Attempt to kick the specified nick from a channel with an optional reason.
  # $bot.param [String] channel The channel from whcih the user will be kicked
  # $bot.param [String] nick The nick of the user being kicked.
  # $bot.param [String] reason The reason for the kick.
  def sendKick(channel, nick, reason = "")
    $bot.connection.sendRaw("KICK #{channel} #{nick} :#{reason}")
  end

  def adminLevel(message)
    return message.bot.admins[message.speaker.partialMask]["AccessLevel"] rescue 0
  end

  def checkAdmin(message, minLevel)
    level = adminLevel(message)

    if level <= minLevel
      $log.info('module') { "Nick #{message.speaker.nick} tried to use #{message.msgArr[0]} with insufficient access level (required: #{minLevel}; level: #{level})." }
      reply(message, "You do not have sufficient access privileges to use that command.")

      return false
    end

    $log.info('module') { "Nick #{message.speaker.nick} used #{message.msgArr[0]} (required: #{minLevel}; level: #{level})." }
    return true
  end

  def sendRaw(str)
    $bot.connection.sendRaw(str)
  end

  def reply(message, str, nickPrefix = true)
    message.bot.connection.reply(message, str, nickPrefix)
  end

  def registerModule(name, description)
    $bot.modHelp.registerModule(name, description)
  end

  def registerCommand(owner, command, help, args = nil)
    $bot.modHelp.registerCommand(owner, command, help, args)
  end

  def default(key, value)
    $bot.modConfig.default(self.class.to_s, key, value)
  end

  def set(key, value)
    $bot.modConfig.put(self.class.to_s, key, value)
  end

  def get(key, default = nil)
    $bot.modConfig.get(self.class.to_s, key, default)
  end

  def getAll()
    $bot.modConfig.getAll(self.class.to_s)
  end

  def getValues()
    $bot.modConfig.getKeys(self.class.to_s)
  end

  def getKeys()
    $bot.modConfig.getValue(self.class.to_s)
  end

  def delete(key)
    $bot.modConfig.delete(self.class.to_s, key)
  end

end
