
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

  register_command("ignores",  :cmd_ignores,  0,  4, nil, "List all active ignores.")
  register_command("ignore",   :cmd_ignore,   1,  4, nil, "Ignore the given hostmask.")
  register_command("unignore", :cmd_unignore, 1,  4, nil, "Remove the given ignore.")

  raise "ignores script requires the ignores module" unless defined? Ignores
end

def cmd_ignores(msg, params)
  if Ignores.empty?
    msg.reply("There are no active ignores.")
    return
  end

  msg.reply(Ignores.join(", "))
end

def cmd_ignore(msg, params)
  mask = params[0]

  mask << "!*@*"  unless mask =~ /[!@*]/
 
  if Ignores.include? params[0]
    msg.reply("Already ignoring #{mask}")
    return
  end

  Ignores << mask

  msg.reply("Ignore added: #{mask}")
end

def cmd_unignore(msg, params)
  mask = params[0]

  mask << "!*@*"  unless mask =~ /[!@*]/

  unless Ignores.include? mask
    msg.reply("No such ignore.")
    return
  end

  Ignores.delete mask

  msg.reply("Ignore removed: #{mask}")
end
