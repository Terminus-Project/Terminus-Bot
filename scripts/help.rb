
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
  register_script("Provide on-protocol help for bot scripts and commands.")

  register_command("help", :cmd_help,         0,  0, "Show help for the given command, or a list of all commands. Parameters: [command]")
  register_command("script", :cmd_script,     0,  0, "Show a description of the given script, or a list of all scripts. Parameters: [script]")
end

def cmd_help(msg, params)
  if params.length == 0
    list_commands(msg)
    return
  end

  name = params[0].downcase

  unless $bot.commands.has_key? name
    msg.reply("There is no help available for that command.")
    return
  end

  command = $bot.commands[name]

  level = msg.connection.users.get_level(msg)

  if command.level > level
    msg.reply("You are not authorized to use that command, so you may not view its help.")
    return
  end

  msg.reply(command.help)
end

def list_commands(msg)
  buf = Array.new

  level = msg.connection.users.get_level(msg)

  $bot.commands.sort_by {|n, c| n}.each do |name, command|
    buf << command.cmd unless command.level > level
  end

  msg.reply(buf.join(", "))
end


def cmd_script(msg, params)
  if params.length == 0
    list_scripts(msg)
    return
  end

  script = $bot.script_info.select {|s| s.name.downcase == params[0].downcase }[0]

  if script == nil
    msg.reply("There is no information available on that script.")
  else
    msg.reply(script.description)
  end
end

def list_scripts(msg)
  buf = Array.new

  $bot.script_info.each do |script|
    buf << script.name
  end

  msg.reply(buf.join(", "))
end

