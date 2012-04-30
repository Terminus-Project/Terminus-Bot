#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

def initialize
  register_script("A Russian Roulette-style game of chance.")

  register_command("roulette", :cmd_roulette,  0,  0, nil, "Pull the trigger. You have a 5/6 chance of surviving.")
end

def cmd_roulette(msg, params)
  return if msg.private? or msg.silent?

  if rand(6) == 0
    if msg.connection.channels[msg.destination_canon].half_op? msg.connection.nick
      msg.raw("KICK #{msg.destination} #{msg.nick} :Bang!")
    else
      msg.reply("Bang!")
    end

    msg.reply("\01ACTION chambers another round and spins the cylinder.\01", false)

  else
    msg.reply("\01ACTION spins the cylinder after #{msg.nick} pulled the trigger on an empty chamber.\01", false)

  end
end
