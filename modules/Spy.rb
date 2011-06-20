
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
  registerModule("Spy", "Relay channel activity from one channel to another (one-way).")

  registerCommand("Spy", "spy", "Begin relaying channel activity from target to destination (but not the other way).", "target destination")
  registerCommand("Spy", "unspy", "Stop relaying channel activity.", "target")
end

def bot_privmsg(message)
  spy(message)
end

def bot_notice(message)
  spy(message)
end

def spy(message)
  spying = get(message.destination, nil)

  return if spying == nil

  sendPrivmsg(spying, "[#{message.destination}] <#{message.speaker.nick}> #{message.message}")
end

def cmd_spy(message)
  return unless checkAdmin(message, 5)

  if message.msgArr.length != 3
    reply(message, "Usage: spy target destination")
    return true
  end

  spying = get(message.msgArr[1], nil)

  if spying != nil
    if spying == message.msgArr[2]
      reply(message, "I am already relaying activity from #{message.msgArr[1]} to #{message.msgArr[2]}.")
    else
      reply(message, "One-way relay from #{message.msgArr[1]} will now send to #{message.msgArr[2]}.")
      set(message.msgArr[1], message.msgArr[2])
    end
  else
    reply(message, "One-way relay from #{message.msgArr[1]} now sending to #{message.msgArr[2]}.")
    set(message.msgArr[1], message.msgArr[2])
  end
end

def cmd_unspy(message)
  return unless checkAdmin(message, 5)

  if message.msgArr.length != 2
    reply(message, "Usage: unspy target")
    return true
  end

  spying = get(message.msgArr[1], nil)

  if spying != nil
    delete(message.msgArr[1])
    reply(message, "I will no longer spy on #{message.msgArr[1]}.")
  else
    reply(message, "I am not spying on #{message.msgArr[1]}.")
  end
end
