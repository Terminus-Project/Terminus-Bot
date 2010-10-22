
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
  $bot.modHelp.registerModule("Cookies", "Exchange or earn delicious (virtual) snacks.")

  $bot.modHelp.registerCommand("Cookies", "cookie", "Give one or more of your cookies to another user. If no nick is given, check how many cookies you have.", "nick number")
  $bot.modHelp.registerCommand("Cookies", "bake", "Bake a dozen cookies for yourself.", "")
  $bot.modHelp.registerCommand("Cookies", "eat", "Eat someone's cookie.", "nick")
end

def cmd_bake(message)
  return true if message.speaker.adminLevel < 3

  current = getCookies(message.speaker.maskedPartialMask)

  current = current + 12

  setCookies(message.speaker.maskedPartialMask, current)

  reply(message, "You now have #{BOLD}#{current}#{NORMAL} cookies.")
end

def cmd_eat(message)
  return true if message.speaker.adminLevel < 3

  if message.msgArr.length != 2
    reply(message, "Usage: eat #{UNDERLINE}nick#{NORMAL}")
    return true
  end

  if not $bot.channels[message.destination].users.include? message.msgArr[1]
    reply(message, "You can only eat cookies of people in the same channel.")
    return false
  end

  receiver = getCookies($bot.channels[message.destination].users[message.msgArr[1]].maskedPartialMask)

  if receiver == 0
    reply(message, "#{message.msgArr[1]} doesn't have any cookies.")
    return true
  end

  setCookies($bot.channels[message.destination].users[message.msgArr[1]].maskedPartialMask, receiver-1)

end

def cmd_cookie(message)

  sender = getCookies(message.speaker.maskedPartialMask)
  sending = 1

  if message.args.empty?
    reply(message, "You currently have #{BOLD}#{sender}#{NORMAL} cookies.")
    return false
  end

  if not $bot.channels[message.destination].users.include? message.msgArr[1]
    reply(message, "You can only give cookies to people in the same channel.")
    return false
  end

  if message.msgArr[2] != nil

    begin
      sending = Integer(message.msgArr[2])
    rescue
      reply(message, "Usage: cookie #{UNDERLINE}nick#{NORMAL} #{UNDERLINE}number#{NORMAL}")
      return true
    end

    if sending < 1
      reply(message, "You must give at least one cookie.")
      return true
    elsif sender < sending
      reply(message, "You only have #{BOLD}#{sender}#{NORMAL} cookies.")
      return true
    end

  end

  receiver = getCookies($bot.channels[message.destination].users[message.msgArr[1]].maskedPartialMask)
  sender = sender - sending
  receiver = receiver + sending

  setCookies(message.speaker.maskedPartialMask, sender)
  setCookies($bot.channels[message.destination].users[message.msgArr[1]].maskedPartialMask, receiver)

  reply(message, "#{BOLD}#{message.speaker.nick}#{NORMAL} gave #{sending} cookie#{sending > 1 ? "s": ""} to #{BOLD}#{message.msgArr[1]}#{NORMAL}.", false)
end

def getCookies(mask)
  cookies = $bot.modConfig.get("cookies", mask)

  if cookies == nil
    cookies = 0
    setCookies(mask, cookies)
  end

  return cookies
end

def setCookies(mask, amount)
  $bot.modConfig.put("cookies", mask, amount)
end
