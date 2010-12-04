
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
  registerModule("Help", "Provide help on using bot commands and modules.")
  registerCommand("Help", "commands", "List all available commands.")
  registerCommand("Help", "modules", "List all loaded modules.")
  registerCommand("Help", "help", "Provide syntax and help for using a command.", "command")
end

def cmd_commands(message)
  commands = $bot.modHelp.commandList.join(", ")

  reply(message, commands)
end

def cmd_modules(message)
  modules = $bot.modHelp.moduleList.join(", ")

  reply(message, modules)
end

def cmd_help(message)
  if message.msgArr.length == 1
    help = "For a list of commands, use #{BOLD}commands#{NORMAL}. For a list of loaded modules, use #{BOLD}modules#{NORMAL}. For help on a specific command, use #{BOLD}help command#{NORMAL}."
  else
    help = $bot.modHelp.getCommandHelp(message.args)
  end

  reply(message, help)
end
