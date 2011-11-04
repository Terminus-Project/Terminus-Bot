
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
  registerModule("Oper", "Automatically OPER the bot on connect.")

  registerCommand("Oper", "oper", "Attempt to OPER the bot.", "")

  default("enabled", false)
  default("username", "")
  default("password", "")
end

def cmd_oper(message)
  return unless checkAdmin(message, 7)

  reply(message, "I will attempt to log in as an IRC operator.")
  sendRaw("OPER #{get("username")} #{get("password")}")
end

def bot_endofmotd(message)
  if get("enabled", false)
    sendRaw("OPER #{get("username")} #{get("password")}")
  end
end
