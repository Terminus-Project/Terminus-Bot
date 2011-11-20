
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


def initialize()
  register_script("help", "Provide on-protocol help for bot scripts and commands.")

  register_command("commands", :cmd_commands, 0,  0, "Show a list of commands.")
  register_command("help", :cmd_help,         1,  0, "Show help for the given command.")
  register_command("scripts", :cmd_scripts,   0,  0, "Show a list of loaded scripts.")
  register_command("script", :cmd_script,     1,  0, "Show a description of the given script.")
end

def cmd_help(msg, params)
  command = $bot.commands.select {|c| c.cmd.downcase == params[0].downcase }[0]

  if command == nil
    msg.reply("There is no help available for that command.")
  else
    msg.reply(command.help)
  end
end

def cmd_commands(msg, params)
  buf = Array.new

  $bot.commands.each do |command|
    buf << command.cmd
  end

  msg.reply(buf.join(", "))
end


def cmd_script(msg, params)
  script = $bot.script_info.select {|s| s.name.downcase == params[0].downcase }[0]

  if script == nil
    msg.reply("There is no information available on that script.")
  else
    msg.reply(script.description)
  end
end

def cmd_scripts(msg, params)
  buf = Array.new

  $bot.script_info.each do |script|
    buf << script.name
  end

  msg.reply(buf.join(", "))
end

