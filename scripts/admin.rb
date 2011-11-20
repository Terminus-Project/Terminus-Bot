
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
  register_script("admin", "Bot administration script.")

  register_command("eval",  :cmd_eval,   1, 10, "Run raw Ruby code.")
  register_command("quit",  :cmd_quit,   1, 10, "Kill the bot.")
  register_command("rehash",:cmd_rehash, 0, 8,  "Reload the configuration file.")
end

def cmd_eval(msg, params)
  msg.raw("PRIVMSG #{msg.destination} :" + eval(params.join(" ")))
end

def cmd_quit(msg, params)
  $bot.quit(params)
end


def cmd_rehash(msg, params)
  $bot.config.read_config
  msg.reply("Done reloading configuration.")
end
