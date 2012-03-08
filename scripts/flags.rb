
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
#


def initialize
  register_script("Modify and query the script flag table")

  register_command("enable", :cmd_enable, 2, 4, "Enable matching channel/script pairs. Args: [server:channel mask] [script mask]")
  register_command("disable", :cmd_disable, 2, 4, "Disable matching channel/script pairs. Args: [server:channel mask] [script mask]")

  register_command("flags", :cmd_flags, 2, 0, "View flags for a particular mask.")
end


def cmd_enable(msg, params)
  count = 0

  $bot.flags.each_value!(params[0], params[1]) do |value|
    count += 1
    true
  end

  msg.reply("Enabled \02#{count}\02 entries")
end


def cmd_disable(msg, params)
  count = 0
  warn = false

  $bot.flags.each_pair!(params[0], params[1]) do |row, col, value|
    if $bot.flags.scripts[my_short_name] == col
      warn = true
      true
    else
      count += 1
      false
    end
  end

  reply = "Disabled \02#{count}\02 entries"
  reply << " (Attempt to disable script '#{my_short_name}' rejected)" if warn
  msg.reply(reply)
end


def cmd_flags(msg, params)
  falsecnt = 0
  truecnt = 0

  $bot.flags.each_value(params[0], params[1]) do |value|
    if value
      truecnt += 1
    else
      falsecnt += 1
    end
  end

  if falsecnt == 0
    msg.reply("I have \02#{truecnt}\02 enabled entries")
  elsif truecnt == 0
    msg.reply("I have \02#{falsecnt}\02 disabled entries")
  else
    msg.reply("I have \02#{truecnt} enabled\02 entries and \02#{falsecnt} disabled\02 entries")
  end
end
      
