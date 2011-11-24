
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
  register_script("Bot administration script.")

  register_command("eval",    :cmd_eval,     1, 10,  "Run raw Ruby code.")
  register_command("quit",    :cmd_quit,     1, 10,  "Kill the bot.")
  register_command("rehash",  :cmd_rehash,   0,  8,  "Reload the configuration file.")
  register_command("includes",:cmd_includes, 0,  9,  "Reload core files with stopping the bot. Warning: may produce undefined behavior.")
  register_command("reload",  :cmd_reload,   1,  9,  "Reload the named script.")
  register_command("unload",  :cmd_unload,   1,  9,  "Unload the named script.")
  register_command("load",    :cmd_load,     1,  9,  "Load the named script.")
end

def die
  unregister_script
  unregister_commands
end

def cmd_eval(msg, params)
  msg.reply(eval(params[0]))
end

def cmd_quit(msg, params)
  $bot.quit(params[0])
end

def cmd_rehash(msg, params)
  $bot.config.read_config
  msg.reply("Done reloading configuration.")
end

def cmd_includes(msg, params)
  load_files("includes")
  msg.reply("Core files reloaded.")
end

def cmd_reload(msg, params)
  $bot.scripts.reload(params[0])
  msg.reply("Reloaded script \02#{params[0]}\02")
end

def cmd_unload(msg, params)
  $bot.scripts.unload(params[0])
  msg.reply("Unloaded script \02#{params[0]}\02")
end

def cmd_load(msg, params)
  $bot.scripts.load_file("scripts/#{params[0]}.rb")
  msg.reply("Loaded script \02#{params[0]}\02")
end
