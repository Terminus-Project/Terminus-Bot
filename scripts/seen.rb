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
  register_script "Tracks when a user is last seen speaking."

  register_command "seen", :cmd_seen, 1, 0, nil, "Check when the given user was last seen \02speaking\02 on IRC."

  register_event :PRIVMSG, :on_message
end

def on_message msg
  return unless msg.destination.start_with? "#" or msg.destination.start_with? "&"

  # This whole process is a bit expensive. Should store
  # this stuff in class instance variables?

  seen_nicks = get_data msg.connection.name, Hash.new

  if msg.text =~ /\01ACTION (.+)\01/
    seen_nicks[msg.nick_canon] = [Time.now.to_i, $1, msg.nick, true]

  elsif msg.text.include? "\01"
    # Don't record CTCPs that aren't ACTIONs.
    return

  else
    seen_nicks[msg.nick_canon] = [Time.now.to_i, msg.text, msg.nick, false]

  end

  store_data msg.connection.name, seen_nicks
end

def cmd_seen msg, params
  # TODO: Clean up variable names
  nick = msg.connection.canonize params[0]

  if msg.nick_canon == nick
    msg.reply "That's you, silly!"
    return
  end

  seen_nicks = get_data msg.connection.name, Hash.new

  unless seen_nicks.has_key? nick
    msg.reply "I have not seen \02#{params[0]}\02."
    return
  end

  time, text, usenick, isaction = seen_nicks[nick]

  time = Time.at(time).to_fuzzy_duration_s

  usenick = params[0] unless usenick

  if isaction
    text = "* #{usenick} #{text}"
  else
    text = "<#{usenick}> #{text}"
  end

  msg.reply "\02#{usenick}\02 was last seen \02#{time} ago\02: #{text}"
end

