
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
  sendRaw("KICK #{message.destination} #{message.msgArr[1]} :#{message.speaker.nick} made me do it!")
end

def cmd_invite(message)
  return false unless permission? message
  sendRaw("INVITE #{message.msgArr[1]} #{message.destination}")
end
