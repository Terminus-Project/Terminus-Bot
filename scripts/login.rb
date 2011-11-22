
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


require 'digest'

def initialize()
  register_script("Provides account log-in functionality.")

  register_command("identify", :cmd_identify, 2, 0, "Log in to the bot.")
end

def die
  unregister_script
  unregister_commands
end

def cmd_identify(msg, params)

  if msg.destination.start_with? "#"
    msg.reply("For security reasons, this command may not be used in channels.")
    return
  end

  stored = get_data(params[0], nil)

  if stored == nil
    msg.reply("Incorrect log-in information.")
    return
  end

  stored_arr = stored["password"].split(":")

  calculated = Digest::MD5.hexdigest(params[1] + ":" + stored_arr[1])
  
  $log.debug("login.cmd_identify") { calculated }

  if stored_arr[0] != calculated
    msg.reply("Incorrect log-in information.")
    return
  end

  msg.connection.users[msg.nick].level = stored["level"]

  msg.reply("Logged in with level #{stored["level"]} authorization.")
end
