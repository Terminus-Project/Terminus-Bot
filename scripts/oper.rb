
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
  register_script("Lets the bot oper up.")

  register_command("oper", :cmd_oper, 1,  6, "Attempt to oper on the named network.")

  register_event("376",   :on_376)
end

def die
  unregister_script
  unregister_commands
  unregister_events
end

def cmd_oper(msg, params)
  oper = get_config(params[0])

  if oper == nil
    msg.reply("There is no oper config for that connection.")
    return
  end

  oper = oper.split(":")

  unless oper.length == 2
    msg.reply("The oper config for that connection is improperly formatted.")
    return
  end

  unless $bot.connections.has_key? params[0]
    msg.reply("I am not currently connected to #{params[0]}.")
    return
  end

  $bot.connections[params[0]].raw("OPER #{oper[0]} #{oper[1]}")
  msg.reply("Sent OPER login information.")
end

def on_376(msg, params)
  oper = get_config(msg.connection.name)

  return if oper == nil

  oper = oper.split(":")

  return unless oper.length == 2

  msg.raw("OPER #{oper[0]} #{oper[1]}")
end
