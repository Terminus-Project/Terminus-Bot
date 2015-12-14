#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2015 Kyle Johnson <kyle@vacantminded.com>
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

need_module! 'regex_handler'

register 'Fix typos.'

regex(/\^[HWUY]/) do
  buf, clipboard, caret = '', '', false

  match = @msg.text.match(/\01ACTION (?<text>.+)\01/)

  if match
    text = match[:text]
    type = :ACTION
  else
    text = @msg.text
    type = @msg.type
  end

  text.each_char do |c|
    if c == '^' and not caret
      caret = true
      next
    end

    if caret

      case c
      when 'H'
        buf.chop!
        caret = false

      when 'W'
        buf, clipboard = delete_last_word buf
        caret = false

      when 'U'
        clipboard = buf.dup
        buf.clear
        caret = false

      when 'Y'
        buf << clipboard
        caret = false

      when '^'
        buf << c

      else
        buf << "^#{c}"
        caret = false

      end

    else
      buf << c

    end

    # prevent excessively huge buffers (possible denial of service)
    buf = buf[0..512]
  end

  buf << '^' if caret

  reply_with_message type, @msg.nick, buf
end

helpers do
  def delete_last_word s
    buf = ''

    if s
      loop do
        buf << s.chars.last
        s.chop!

        break if s.chars.last == ' ' || s.empty?
      end
    end

    [s, buf.reverse]
  end

  def reply_with_message type, nick, message
    case type
    when :ACTION
      reply "* #{nick} #{message}", false
    when :PRIVMSG
      reply "<#{nick}> #{message}", false
    when :NOTICE
      reply "-#{nick}- #{message}", false
    end
  end
end

# vim: set tabstop=2 expandtab:

