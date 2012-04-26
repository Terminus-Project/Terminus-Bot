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
  raise "ignores script requires the ignores module" unless defined? MODULE_LOADED_IGNORES

  register_script("Manipulate the bot's hostmask-based ignore list.")

  register_command("ignores",  :cmd_ignores,  0,  4, nil, "List all active ignores.")
  register_command("ignore",   :cmd_ignore,   1,  4, nil, "Ignore the given hostmask.")
  register_command("unignore", :cmd_unignore, 1,  4, nil, "Remove the given ignore.")
end

def cmd_ignores(msg, params)
  if Ignores.empty?
    msg.reply("There are no active ignores.")
    return
  end

  msg.reply(Ignores.join(", "))
end

def cmd_ignore(msg, params)
  mask = params[0]

  mask << "!*@*"  unless mask =~ /[!@*]/
 
  if Ignores.include? params[0]
    msg.reply("Already ignoring #{mask}")
    return
  end

  Ignores << mask

  msg.reply("Ignore added: #{mask}")
end

def cmd_unignore(msg, params)
  mask = params[0]

  mask << "!*@*"  unless mask =~ /[!@*]/

  unless Ignores.include? mask
    msg.reply("No such ignore.")
    return
  end

  Ignores.delete mask

  msg.reply("Ignore removed: #{mask}")
end
