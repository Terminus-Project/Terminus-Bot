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

@@pending ||= {}

register "Bot-to-user round trip time checker."

command 'ping', 'Measure the time it takes for the bot to receive a reply to a CTCP PING from your client.' do
  @@pending[@connection.name] ||= {}

  if @@pending[@connection.name].has_key? @msg.nick
    if Time.now.to_f - @@pending[@connection.name][@msg.nick] > 30
      @@pending[@connection.name].delete(@msg.nick)
    else
      reply "I'm still waiting on a reply to the last ping I sent you. (It will expire 30 seconds after it was sent.)"
      next
    end
  end

  @connection.raw_fast "PRIVMSG #{@msg.nick} :\01PING\01"

  @@pending[@connection.name][@msg.nick] = Time.now.to_f
end

event :NOTICE do
  next unless @@pending.has_key? @connection.name

  next unless @@pending[@connection.name][@msg.nick]

  if @msg.text.start_with? "\01PING"
    time = Time.now.to_f - @@pending[@connection.name][@msg.nick]
    @@pending[@connection.name].delete(@msg.nick)

    reply "Your ping time: #{sprintf("%2.4f", time)} seconds."
  end
end

