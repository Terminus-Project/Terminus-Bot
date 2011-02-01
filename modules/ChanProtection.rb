
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
  registerModule("ChanProtection", "Protection against various types of channel spam, flooding, or unwanted activity.")

  registerCommand("ChanProtection", "badwords", "View or modify the badwords list.", "channel option [value]")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")
  #$bot.modHelp.registerCommand("ChanProtection", "", "", "")

  default("kickCount", 0)
end

def bot_privmsg(message)
  protectionCheck(message)
end

def bot_notice(message)
  protectionCheck(message)
end

def bot_joinChannel(message)
  if message.speaker.nick == $bot.config["Nick"]
    initChan(message.message)
  end
end

def cmd_badwords(message)
  return true unless permission? message

  if message.msgArr.length == 1
    reply(message, "Usage: badwords channel option [value]")
    return true
  elsif message.msgArr.length == 2
    reply(message, "Possible commands: enable, disable, addword, removeword, warning, kickreason, bantime, list")
    return true
  end

  channel = message.msgArr[1]
  settings = get(channel, nil)

  if settings == nil
    initChan(channel)
    settings = get(channel, nil)
  end

  case message.msgArr[2]
  when "enable"

    settings["badwords"]["enabled"] = true
    set(channel, settings)

  when "disable"

    settings["badwords"]["enabled"] = false
    set(channel, settings)

  when "addword"

    if message.msgArr.length < 4
      reply(message, "Usage: badwords channel addword word")
      return true
    end

    args = message.msgArr[3..message.msgArr.length].join(" ")

    settings["badwords"]["words"] << args
    set(channel, settings)
    reply(message, "I have added #{args} to the badwords list for #{channel}.")

  when "removeword"
   if message.msgArr.length < 4
      reply(message, "Usage: badwords channel addword word")
      return true
    end

    args = message.msgArr[3..message.msgArr.length-2]

    if settings["badwords"]["words"].include? args
      settings["badwords"]["words"].delete args
      set(channel, settings)

      reply(message, "I have removed #{args} from the badwords list for #{channel}.")
    end

  when "warning"
   if message.msgArr.length < 4
      reply(message, "Current badwords warning for #{channel}: #{settings["badwords"]["warning"]}")
      reply(message, "To change it, use the same command, but include the new warning at the end.")
      return true
    end

    args = message.msgArr[3..message.msgArr.length-2]

    settings["badwords"]["warning"] = args
    set(channel, settings)

    reply(message, "I have changed the badwords warning for #{channel} to #{args}.")
  when "kickreason"
   if message.msgArr.length < 4
      reply(message, "Current badwords kick reason for #{channel}: #{settings["badwords"]["kickReason"]}")
      reply(message, "To change it, use the same command, but include the new kick reason at the end.")
      return true
    end

    args = message.msgArr[3..message.msgArr.length-2]

    settings["badwords"]["kickReason"] = args
    set(channel, settings)

    reply(message, "I have changed the badwords kick reason for #{channel} to #{args}.")
  when "bantime"
   if message.msgArr.length < 4
      reply(message, "Current badwords ban time (minutes) for #{channel}: #{settings["badwords"]["bantime"]}")
      reply(message, "To change it, use the same command, but include the new ban time (in minutes) at the end.")
      return true
    end

    args = message.msgArr[3..message.msgArr.length-2]

    settings["badwords"]["bantime"] = args
    set(channel, settings)

    reply(message, "I have changed the badwords ban time for #{channel} to #{args}.")
  when "list"
    reply(message, "Current badwords list for #{channel}: #{settings["badwords"]["words"].join(", ")}")
  end
end

###############
# Main Worker #
###############

def protectionCheck(message)
  return if message.private?

  channel = message.destination

  settings = get(channel, nil)

  unless settings == nil
    if settings["badwords"]["enabled"]

      words = settings["badwords"]["words"]

      words.each { |word|

        if message.message.include? word
          doPunishment(message, "badwords")
          break
        end
      
      }

    end


  end
end

###############
#   Helpers   #
###############

def permission?(message, requireOps = true)
  return false unless message.msgArr.length >= 2

  channel = message.msgArr[1]

  if not message.private?
    reply(message, "Please use this command in a private query.", true)
    return false
  elsif not $bot.channels.has_key? channel
    reply(message, "I must be in that channel for you to use this command.", true)
    return false
  elsif not $bot.channels[channel].users[message.speaker.nick].isChannelOp?
    reply(message, "Only channel operators may use this command.", true)
    return false
  elsif not $bot.channels[channel].users[$bot.config["Nick"]].isChannelOp? and requireOps
    reply(message, "In order to use that command, I need to be a channel operator.", true)
    return false
  end

  return true
end


def initChan(channel)
  settings = get(channel, nil)

  if settings == nil
    skel = Hash.new
    skel["badwords"] = Hash.new
    skel["badwords"]["enabled"] = false
    skel["badwords"]["warning"] = "You have triggered badwords protection. To avoid punishment, please stop immediately."
    skel["badwords"]["kickReason"] = "Badwords protection triggered. [%d] [#%k] (Banned %b minutes.)"
    skel["badwords"]["banTime"] = 10
    skel["badwords"]["words"] = Array.new
    skel["badwords"]["warned"] = Array.new

    #skel[""] = Hash.new
    #skel[""] = Hash.new
    #skel[""] = Hash.new
    #skel[""] = Hash.new
    #skel[""] = Hash.new

    set(channel, skel)
  end
end

def doPunishment(message, trigger)
  user = message.speaker.maskedPartialMask

  if warned? user, message.destination, trigger
    banTime = getBanTime(message.destination, trigger)
    doKick(message, trigger, banTime)

    if banTime > 0
      sendMode(message.destination, "+b", message.speaker.maskedFullMask)
      banTime = banTime * 60 + Time.now.to_i

      $scheduler.add("#{trigger} protection ban expiration for #{message.speaker.nick}", Proc.new {sendMode(message.destination, "-b", message.speaker.maskedFullMask)}, banTime, false)
    end
  else
    doWarn(message, trigger)
  end

end

def doKick(message, trigger, banTime)
  kickReason = getKickReason(message.destination, trigger)
  kickCount = get("kickCount")
  set("kickCount", kickCount + 1)

  # TODO: Make this less horrible.

  #kickReason.gsub!("%d", Time.utc.strftime("%H:%M:%S %Z"))
  kickReason.gsub!("%b", "#{banTime}")
  kickReason.gsub!("%k", "#{kickCount}")
  kickReason.gsub!("%n", message.speaker.nick)

  sendKick(message.destination, message.speaker.nick, kickReason)
end

def doWarn(message, trigger)
  warningMsg = getWarning(message.destination, trigger)

  #warningMsg.gsub!("%d", Time..strftime("%H:%M:%S %Z"))
  #warningMsg.gsub!("%b", banTime)
  warningMsg.gsub!("%n", message.speaker.nick)

  sendNotice(message.speaker.nick, warningMsg)

  settings = get(message.destination)
  settings[trigger]["warned"] << message.speaker.maskedPartialMask
end

def warned?(user, channel, trigger)
  settings = get(channel)

  return settings[trigger]["warned"].include? user
end

def getBanTime(channel, trigger)
  settings = get(channel)
  return settings[trigger]["banTime"]
end

def getWarning(channel, trigger)
  settings = get(channel)

  return settings[trigger]["warning"]
end

def getKickReason(channel, trigger)
  settings = get(channel)

  return settings[trigger]["kickReason"]
end
