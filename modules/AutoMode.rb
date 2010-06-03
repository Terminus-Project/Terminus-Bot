
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
  $bot.modHelp.registerModule("AutoMode", "The bot may be configured to automatically set modes to every user on join.")

  $bot.modHelp.registerCommand("AutoMode", "automode list", "List the modes which will automatically be applied to joining users in this channel.")
  $bot.modHelp.registerCommand("AutoMode", "automode add", "Add a mode to automatically apply to joining users. A + or - should be given, depending on IRC daemon requirements.", "mode(s)")
  $bot.modHelp.registerCommand("AutoMode", "automode delete", "No longer set the specified mode for joining users. A + or - must be given if one is included in the setting that is being deleted.", "mode(s)")
end

def cmd_automode(message)

  if message.private?
    reply(message, "Please use this in the channel you want to modify.", true)
    return
  elsif not $bot.channels[message.destination].users[message.speaker.nick].isChannelOp?
    reply(message, "Only channel operators may use this command.", true)
    return
  end

  case message.msgArr[1]
    when "add"

      if message.msgArr.length == 3
        config = $bot.modConfig.get("automode", message.destination)

        config = Array.new if config == nil

        config << message.msgArr[2]
        $bot.modConfig.put("automode", message.destination, config)
        reply(message, "Automode added.", true)
      else
        reply(message, "Please provide the additional modes to set on join: automode add <mode(s)>", true)
      end
    when "delete"
      config = $bot.modConfig.get("automode", message.destination)
      if config == nil
        reply(message, "No automodes are set for this channel.", true)
      else
        if config.include? message.msgArr[2]
          config.delete message.msgArr[2]
          reply(message, "Automode deleted.", true)
        else
          reply(message, "That automode was not set.", true)
        end
      end
    when "list"
      config = $bot.modConfig.get("automode", message.destination)
      if config == nil
        reply(message, "No automodes are set for this channel.", true)
      else
        reply(message, config.join(", "), true)
      end

    else
      reply(message, "Try: add, delete, or list", true)
  end

end

def bot_joinChannel(message)
  config = $bot.modConfig.get("automode", message.message)
  return nil if config == nil

  modeParams = ""

  config.length.times { modeParams = "#{modeParams} #{message.speaker.nick}" }

  sendMode(message.message, config.join(""), modeParams)
end

