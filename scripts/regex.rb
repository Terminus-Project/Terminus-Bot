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

require 'timeout'

def initialize
  register_script "Show corrected text with s/regex/replacement/ is used and allow searching with g/regex/."

  register_event :PRIVMSG, :on_privmsg
  register_event :PART,    :on_part

  @messages = {}
end

def on_part msg
  return unless @messages.has_key? msg.connection.name and msg.me?

  @messages[msg.connection.name].delete msg.destination
end

def on_privmsg msg
  return if msg.private?

  match = msg.text.match(/^(?<action>(s|g))\/(?<search>.+?)\/(?<replace>.*?)(\/(?<flags>.*))?$/)

  if match
    return unless @messages.has_key? msg.connection.name
    return unless @messages[msg.connection.name].has_key? msg.destination

    case match[:action]
    when "g"
      grep msg, match
    when "s"
      substitute msg, match
    end

    return
  end

  @messages[msg.connection.name] ||= {}
  @messages[msg.connection.name][msg.destination] ||= []

  if msg.text =~ /\01ACTION (.+)\01/
    @messages[msg.connection.name][msg.destination] << [msg.nick, $1,       true]
  else
    @messages[msg.connection.name][msg.destination] << [msg.nick, msg.text, false]
  end


  if @messages[msg.connection.name][msg.destination].length > get_config(:buffer, 100).to_i
    @messages[msg.connection.name][msg.destination].shift
  end
end

def grep msg, match
  Timeout::timeout(get_config(:run_time, 2).to_i) do
    # match[:replace] is flags because whatever
    search, flags, opts = match[:search], match[:replace], Regexp::EXTENDED

    opts |= Regexp::IGNORECASE if flags and flags.include? "i"

    search = Regexp.new match[:search].gsub(/\s/, '\s'), opts

    @messages[msg.connection.name][msg.destination].reverse.each do |message|

      if search.match message[1]

        if message[2]
          msg.reply "* #{message[0]} #{message[1]}", false
        else
          msg.reply "<#{message[0]}> #{message[1]}", false
        end

        return
      end

    end
  end
end

def substitute msg, match
  Timeout::timeout(get_config(:run_time, 2).to_i) do
    replace, flags, opts = match[:replace], match[:flags], Regexp::EXTENDED

    opts |= Regexp::IGNORECASE if flags and flags.include? "i"

    search = Regexp.new match[:search].gsub(/\s/, '\s'), opts

    @messages[msg.connection.name][msg.destination].reverse.each do |message|

      if search.match message[1]
        new_msg = ((flags and flags.include?("g")) ? message[1].gsub(search, replace) : message[1].sub(search, replace) )

        if message[2]
          msg.reply "* #{message[0]} #{new_msg}", false
        else
          msg.reply "<#{message[0]}> #{new_msg}", false
        end

        return
      end

    end
  end
end
