
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

def initialize()
  $bot.modHelp.registerModule("Oper", "Automatically OPER the bot on connect.")

  $bot.modHelp.registerCommand("Oper", "oper", "Attempt to OPER the bot.", "")

  $bot.modConfig.default("Oper", "enabled", false)
  $bot.modConfig.default("Oper", "username", "")
  $bot.modConfig.default("Oper", "password", "")
end

def cmd_oper(message)
  return if message.speaker.adminLevel < 8

  reply(message, "I will attempt to log in as an IRC operator.")
  sendRaw("OPER #{$bot.modConfig.get("Oper", "username")} #{$bot.modConfig.get("Oper", "password")}")
end

def bot_endofmotd(message)
  if $bot.modConfig.get("Oper", "enabled")
    sendRaw("OPER #{$bot.modConfig.get("Oper", "username")} #{$bot.modConfig.get("Oper", "password")}")
  end
end
