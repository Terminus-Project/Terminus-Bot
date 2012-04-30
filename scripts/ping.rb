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
  register_script("Bot to user response time checker.")

  register_command("ping", :cmd_ping,  0,  0, nil, "Measure the time it takes for the bot to receive a reply to a CTCP PING from your client.")

  register_event(:NOTICE, :on_notice)

  @pending = Hash.new
end

def on_notice(msg)
  unless @pending.has_key? msg.connection.name
    return
  end

  unless @pending[msg.connection.name][msg.nick]
    return
  end

  if msg.text.start_with? "\01PING"
    time = Time.now.to_f - @pending[msg.connection.name][msg.nick]
    @pending[msg.connection.name].delete(msg.nick)

    msg.reply("Your ping time: #{sprintf("%2.4f", time)} seconds.")
  end
end

def cmd_ping(msg, params)
  @pending[msg.connection.name] ||= Hash.new

  if @pending[msg.connection.name].has_key? msg.nick
    if Time.now.to_f - @pending[msg.connection.name][msg.nick] > 30
      @pending[msg.connection.name].delete(msg.nick)
    else
      msg.reply("I'm still waiting on a reply to the last ping I sent you. (It will expire 30 seconds after it was sent.)")
      return
    end
  end

  msg.connection.raw_fast("PRIVMSG #{msg.nick} :\01PING\01")

  # Get a fresh time for slightly increased accuracy.
  @pending[msg.connection.name][msg.nick] = Time.now.to_f
end
