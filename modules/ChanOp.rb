
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

def initialize
  registerModule("ChannelOperator", "Allows channel operators to use the bot to perform channel moderation functions.")

  registerCommand("ChannelOperator", "voice", "Set mode +v to nick.", "nick")
  registerCommand("ChannelOperator", "devoice", "Set mode -v to nick.", "nick")
  registerCommand("ChannelOperator", "op", "Set mode +o to nick.", "nick")
  registerCommand("ChannelOperator", "deop", "Set mode +o to nick.", "nick")
  registerCommand("ChannelOperator", "halfop", "Set mode +h to nick.", "nick")
  registerCommand("ChannelOperator", "dehalfop", "Set mode -h to nick.", "nick")
  registerCommand("ChannelOperator", "admin", "Set mode +a to nick.", "nick")
  registerCommand("ChannelOperator", "deadmin", "Set mode -a to nick.", "nick")
  registerCommand("ChannelOperator", "owner", "Set mode +q to nick.", "nick")
  registerCommand("ChannelOperator", "deowner", "Set mode -q to nick.", "nick")
  registerCommand("ChannelOperator", "mode", "Sets channel mode.", "mode")
  registerCommand("ChannelOperator", "kick", "Kicks the specified user from the channel.", "nick")
  registerCommand("ChannelOperator", "invite", "Invites nick to the channel.", "nick")
  registerCommand("ChannelOperator", "topic", "Sets the topic, if given. Otherwise, sends an empty TOPIC command to the server. Depending on server configuration, this may clear the channel topic.", "[topic]")
end

def permission?(message, requireOps = true)
  if message.private?

    reply(message, "Please use this in the channel you want to modify.", true)
    return false

  elsif not $bot.channels[message.destination].users[message.speaker.nick].isChannelOp?

    reply(message, "Only channel operators may use this command.", true)
    return false

  elsif not $bot.channels[message.destination].users[$bot.config["Nick"]].isChannelOp? and requireOps

    reply(message, "In order to use that command, I need to be a channel operator.", true)
    return false

  end

  return true
end

def cmd_topic(message)
  return false unless permission? message
  sendRaw("TOPIC #{message.destination} #{message.args}")
end

def cmd_op(message)
  return false unless permission? message
  sendMode(message.destination, "+o", message.args)
end

def cmd_deop(message)
  return false unless permission? message
  sendMode(message.destination, "-o", message.args)
end

def cmd_halfop(message)
  return false unless permission? message
  sendMode(message.destination, "+h", message.args)
end

def cmd_dehalfop(message)
  return false unless permission? message
  sendMode(message.destination, "-h", message.args)
end

def cmd_voice(message)
  return false unless permission? message
  sendMode(message.destination, "+v", message.args)
end

def cmd_devoice(message)
  return false unless permission? message
  sendMode(message.destination, "-v", message.args)
end

def cmd_admin(message)
  return false unless permission? message
  sendMode(message.destination, "+a", message.args)
end

def cmd_deadmin(message)
  return false unless permission? message
  sendMode(message.destination, "-a", message.args)
end

def cmd_owner(message)
  return false unless permission? message
  sendMode(message.destination, "+q", message.args)
end

def cmd_deowner(message)
  return false unless permission? message
  sendMode(message.destination, "-q", message.args)
end

def cmd_mode(message)
  return false unless permission? message
  sendMode(message.destination, message.args)
end

def cmd_kick(message)
  return false unless permission? message
  sendKick(message.destination, message.msgArr[1], "#{message.speaker.nick} made me do it!")
end

def cmd_invite(message)
  return false unless permission? message
  sendRaw("INVITE #{message.msgArr[1]} #{message.destination}")
end
