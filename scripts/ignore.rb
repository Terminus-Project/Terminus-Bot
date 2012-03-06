
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
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
  register_script("Manipulate the bot's hostmask-based ignore list.")

  register_command("ignores",  :cmd_ignores,  0,  4, "List all active ignores.")
  register_command("ignore",   :cmd_ignore,   1,  4, "Ignore the given nick or hostmask.")
  register_command("unignore", :cmd_unignore, 1,  4, "Remove the given ignore.")
end

def cmd_ignores(msg, params)
  if $bot.ignores.empty?
    msg.reply("There are no active ignores.")
    return
  end

  msg.reply($bot.ignores.join(", "))
end

def cmd_ignore(msg, params)
  $bot.ignores << params[0]

  msg.reply("Ignore added.")
end

def cmd_unignore(msg, params)

  unless $bot.ignores.include? params[0]
    msg.reply("No such ignore.")
    return
  end

  $bot.ignores.delete params[0]

  msg.reply("Ignore removed.")
end
