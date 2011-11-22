
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


def initialize()
  register_script("Show information about the networks to which the bot is connected.")

  register_command("networks", :cmd_networks, 0,  0, "Show a list of networks to which the bot is connected.")
end

def die
  unregister_script
  unregister_commands
end

def cmd_networks(msg, params)
  buf = Array.new

  $bot.connections.each_value do |connection|
    buf << connection.to_s
  end

  msg.reply(buf.join(", "))
end
