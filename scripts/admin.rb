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
  register_script("Bot administration script.")

  register_command("quit",     :cmd_quit,     0, 10, nil, "Kill the bot.")
  register_command("reconnect",:cmd_reconnect,1, 10, nil, "Reconnect the specified connection.")

  register_command("rehash",   :cmd_rehash,   0,  8, nil, "Reload the configuration file.")
  register_command("nick",     :cmd_nick,     1,  7, nil, "Change the bot's nick for this connection.")

  register_command("lib", :cmd_lib, 0,  9, nil, "Reload core files with stopping the bot. Warning: may produce undefined behavior.")
  register_command("reload",   :cmd_reload,   1,  9, nil, "Reload one or more scripts.")
  register_command("unload",   :cmd_unload,   1,  9, nil, "Unload one or more scripts.")
  register_command("load",     :cmd_load,     1,  9, nil, "Load the specified script.")
end

def cmd_quit(msg, params)
  EM.next_tick { params.empty? ? Bot.quit : Bot.quit(params[0]) }
end

def cmd_reconnect(msg, params)
  name = params[0].to_sym

  unless Bot::Connections.has_key? name
    msg.reply("No such connection.")
    return
  end

  Bot::Connections[name].reconnect
  msg.reply("Reconnecting.")
end

def cmd_rehash(msg, params)
  Bot::Conf.read_config
  msg.reply("Done reloading configuration.")

  #Bot.start_connections
end

def cmd_nick(msg, params)
  msg.raw("NICK #{params[0]}")

  msg.reply("Nick changed to #{params[0]}")
end

def cmd_lib(msg, params)
  load_lib
  msg.reply("Core files reloaded.")
end

def cmd_reload(msg, params)
  op = proc {
    arr, buf = params[0].split, []

    arr.each do |script|

      begin
        Bot::Scripts.reload(script)
        buf << script

      rescue => e
        msg.reply("Failed to reload \02#{script}\02: #{e}")
      end

    end
    
    msg.reply("Reloaded script#{"s" if buf.length > 1} \02#{buf.join(", ")}\02") unless buf.empty?
  }

  EM.defer(op)
end

def cmd_unload(msg, params)
  op = proc {
    arr, buf = params[0].split, []

    arr.each do |script|

      begin
        Bot::Scripts.unload(script)
        buf << script

      rescue => e
        msg.reply("Failed to unload \02#{script}\02: #{e}")
      end

    end
    
    msg.reply("Unloaded script#{"s" if buf.length > 1} \02#{buf.join(", ")}\02") unless buf.empty?
  }

  EM.defer(op)
end

def cmd_load(msg, params)
  op = proc {
    begin
      Bot::Scripts.load_file("scripts/#{params[0]}.rb")
      msg.reply("Loaded script \02#{params[0]}\02")
    rescue => e
      msg.reply("Failed to load \02#{params[0]}\02: #{e}")
    end
  }

  EM.defer(op)
end

