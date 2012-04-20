
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
  register_script("A Russian Roulette-style game of chance.")

  register_command("roulette", :cmd_roulette,  0,  0, nil, "Pull the trigger. You have a 5/6 chance of surviving.")
end

def cmd_roulette(msg, params)
  return if msg.private? or msg.silent?

  if rand(6) == 0
    if msg.connection.channels[msg.destination].half_op? msg.connection.nick
      msg.raw("KICK #{msg.destination} #{msg.nick} :Bang!")
    else
      msg.reply("Bang!")
    end

    msg.reply("\01ACTION chambers another round and spins the cylinder.\01", false)

  else
    msg.reply("\01ACTION spins the cylinder after #{msg.nick} pulled the trigger on an empty chamber.\01", false)

  end
end
