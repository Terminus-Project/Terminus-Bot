
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
  registerModule("Say", "Basic speaking commands.")

  registerCommand("Say", "act", "Perform an action (as in /me).", "action")
  registerCommand("Say", "say", "Say text.", "text")
end

def cmd_say(message)
  message.reply(message.args, false)
end

def cmd_act(message)
  message.reply("#{1.chr}ACTION #{message.args}#{1.chr}", false)
end

