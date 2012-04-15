
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
  register_script("Show bot uptime and usage information.")

  register_command("uptime", :cmd_uptime,  0,  0, nil, "Show how long the bot has been active.")
end

def cmd_uptime(msg, params)
  since = File.ctime(PID_FILE).to_duration_s
  msg.reply("I was started #{since} ago. \02In:\02 #{$bot.lines_in} lines (#{sprintf("%.4f", $bot.bytes_in / 1024.0)} KiB) \02Out:\02 #{$bot.lines_out} lines (#{sprintf("%.4f", $bot.bytes_out / 1024.0)} KiB)")
end
