
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

  register_command("enable",  :cmd_enable,  2, 4, "Enable scripts in the given server and channel. Wildcards are supported. Parameters: [server:channel] [scripts]")
  register_command("disable", :cmd_disable, 2, 4, "Disable scripts in the given server and channel. Wildcards are supported. Parameters: [server:channel] [scripts]")
  register_command("flags",   :cmd_flags,   2, 0, "View flags for a particular mask.")
end


def cmd_enable(msg, params)
  count = 0

  $bot.flags.each_value!(params[0], params[1]) do |value|
    count += 1 unless value
    true
  end

  msg.reply("Changed \02#{count}\02 entries to \02enabled\02")
end


def cmd_disable(msg, params)
  count = 0
  warn_rejected = false

  privileged = get_config("privileged", "").split(/,/)
  privileged.map! { |name| $bot.flags.scripts[name] }

  $bot.flags.each_pair!(params[0], params[1]) do |row, col, value|

    if privileged.include? col
      warn_rejected = true
      true
    else
      count += 1 if value
      false
    end

  end

  reply = "Changed \02#{count}\02 entries to \02disabled\02"
  reply << " (Attempt to disable a privileged script rejected)" if warn_rejected
  msg.reply(reply)
end


def cmd_flags(msg, params)
  trues, falses, rows, cols = [], [], [], []

  $bot.flags.each_pair(params[0], params[1]) do |row, col, value|

    rows << row unless rows.include? row
    cols << col unless cols.include? col

    if value
      trues << [row, col]
    else
      falses << [row, col]
    end

  end


  if trues.length == 0 and falses.length == 0
    msg.reply("That mask produced no matches")

  elsif trues.length == 0
    msg.reply("All matches are \02disabled\02")

  elsif falses.length == 0
    msg.reply("All matches are \02enabled\02")

  elsif rows.length == 1

    truecol = trues.map { |item| $bot.flags.script_name(item[1]) }
    falsecol = falses.map { |item| $bot.flags.script_name(item[1]) }

    if trues.length < falses.length
      msg.reply("Enabled scripts in \02#{rows[0].join(':')}\02 are #{truecol.join(', ')}")
    else
      msg.reply("Disabled scripts in \02#{rows[0].join(':')}\02 are #{falsecol.join(', ')}")
    end

  elsif cols.length == 1

    truerow = trues.map { |item| item[0].join(':') }
    falserow = falses.map { |item| item[0].join(':') }
    script = $bot.flags.script_name(cols[0])

    if trues.length < falses.length
      msg.reply("Enabled channels for \02#{}\02 are #{truerow.join(', ')}")
    else
      msg.reply("Disabled channels for \02#{}\02 are #{falserow.join(', ')}")
    end

  else
    msg.reply("There are \02#{trues.length} enabled\02 and \02#{falses.length} disabled\02 entries")
  end
end
      
