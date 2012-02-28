
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
  register_script("Provides several game commands.")

  register_command("dice",        :cmd_dice,       1,  0, "Roll dice. Parameters: <count>d<sides>")
  register_command("eightball",   :cmd_eightball,  0,  0, "Shake the 8-ball.")
  register_command("coin",        :cmd_coin,       0,  0, "Flip a coin.")
end

def cmd_dice(msg, params)

  arr = params[0].split("d")

  if arr.length != 2
    msg.reply("Syntax: <count>d<size>")
    return
  end

  count = arr[0].to_i
  sides = arr[1].to_i

  if count > 100
    msg.reply("You may only roll up to 100 dice.")
    return
  end

  if sides > 99
    msg.reply("Dice may only have up to 99 sides.")
    return
  end

  if count <= 0 or sides <= 0
    msg.reply("The number of dice and their sides must be positive numbers larger than 0.")
    return
  end

  rolls = Hash.new(0)
  rolls_a = Array.new

  count.times { rolls[rand(sides)+1] += 1 }
  rolls.each_pair { |r, c| rolls_a << "#{r}#{(c > 1 ? "x#{c}" : "")}" }

  msg.reply(rolls_a.sort.join(", ") + " \02Sum: #{rolls.keys.inject(:+)}\02")
end

def cmd_eightball(msg, params)
  msg.reply([ "Most likely" ,   "It is certain",
    "As I see it, yes",         "Signs point to yes",
    "Outlook Good",             "It is decidedly so",
    "My sources say Yes ",      "Yes, Definetly",
    "Without a doubt",          "You may rely on it",
    "YES",                      "Very doubtful",
    "My sources say NO",        "My reply is NO",
    "Don't count on it",        "Outlook not so good",
    "Concentrate and ask again","Cannot predict now",
    "Reply hazy, try again",    "Ask again later",
    "Better not tell you now" ].sample)
end

def cmd_coin(msg, params)
  msg.reply(["Heads", "Tails"].sample)
end
