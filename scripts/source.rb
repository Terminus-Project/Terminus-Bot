
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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
  register_script("Provides the SOURCE command.")

  register_command("source", :cmd_source, 0, 0, "Share info about the bot and its source code.")
end

def die
  unregister_script
  unregister_commands
end

def cmd_source(msg, params)
  msg.reply("I am Terminus-Bot, a multithreaded Ruby IRC bot (version: #{VERSION}). You can find my source code and other information about me at: https://github.com/kabaka/Terminus-Bot")
end
