
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


def initialize
  register_script("Provides SAY and ACT commands for making the bot speak in channel.")

  register_command("say", :say,  1,  1, "Speak the given text.")
  register_command("act", :act,  1,  1, "Act the given text (CTCP ACTION).")
end

def die
  unregister_script
  unregister_commands
end

def say(msg, params)
  msg.reply(params[0], false)
end

def act(msg, params)
  msg.reply("\01ACTION #{params[0]}\01", false)
end
