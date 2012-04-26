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

def initialize()
  register_script("Provide on-protocol help for bot scripts and commands.")

  register_command("help", :cmd_help,         0,  0, nil, "Show help for the given command, or a list of all commands. Parameters: [command]")
  register_command("script", :cmd_script,     0,  0, nil, "Show a description of the given script, or a list of all scripts. Parameters: [script]")
end

def cmd_help(msg, params)
  if params.empty?
    list_commands(msg)
    return
  end

  name = params[0].downcase

  unless Bot::Commands.has_key? name
    msg.reply("There is no help available for that command.")
    return
  end

  command = Bot::Commands[name]

  level = msg.connection.users.get_level(msg)

  if command.level > level
    msg.reply("You are not authorized to use that command, so you may not view its help.")
    return
  end

  msg.reply(command.help)
end

def list_commands(msg)
  buf = Array.new

  level = msg.connection.users.get_level(msg)

  Bot::Commands.sort_by {|n, c| n}.each do |name, command|
    buf << command.cmd unless command.level > level
  end

  msg.reply(buf.join(", "))
end


def cmd_script(msg, params)
  if params.empty?
    list_scripts(msg)
    return
  end

  script = Bot::Scripts.script_info.select {|s| s.name.downcase == params[0].downcase }[0]

  if script == nil
    msg.reply("There is no information available on that script.")
  else
    msg.reply(script.description)
  end
end

def list_scripts(msg)
  buf = Array.new

  Bot::Scripts.script_info.each do |script|
    buf << script.name
  end

  msg.reply(buf.join(", "))
end

