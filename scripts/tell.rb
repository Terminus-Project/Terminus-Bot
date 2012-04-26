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
  register_script("Leave messages for inactive users.")

  register_event(:PRIVMSG, :on_privmsg)

  register_command("tell",  :cmd_tell,  2,  0, nil, "Have me tell the given user something the next time they speak. Parameters: nick message")
end

def on_privmsg(msg)
  tells = get_data(msg.connection.name, Hash.new)

  return unless tells.has_key? msg.nick_canon

  tells[msg.nick_canon].each do |tell|
    time = Time.at(tell[0]).strftime("%Y-%m-%d %H:%M:%S %Z")

    msg.reply("Tell from \02#{tell[1]}\02 (#{time}): #{tell[2]}")
  end
  
  tells.delete(msg.nick_canon)
end

def cmd_tell(msg, params)
  tells = get_data(msg.connection.name, Hash.new)

  dest = msg.connection.canonize params[0]
  
  if tells.has_key? dest
    if tells[dest].length > get_config(:max, 5).to_i
      msg.reply("No more tells can be left for that nick.")
      return
    end
  else
    tells[dest] = Array.new
  end

  tells[dest] << [Time.now.to_i, msg.nick, params[1]]

  store_data(msg.connection.name, tells)

  $log.info("tell.cmd_tell") { "Added: #{tells[dest]}" }

  msg.reply("I will try to deliver your message.")
end
