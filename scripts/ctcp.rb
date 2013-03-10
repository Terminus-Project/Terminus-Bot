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

register 'Reply to some CTCP requests.'

event :PRIVMSG do
  if @msg.text =~ /\01([^\s]+) ?(.*)\01/

    case $1.to_sym

      when :VERSION
        send_notice @msg.nick, "\01VERSION #{VERSION}\01"
      
      when :URL
        send_notice @msg.nick, "\01URL http://terminus-bot.com/\01"

      when :TIME
        # implements rfc 822 section 5 as date-time
        send_notice @msg.nick, "\01TIME #{DateTime.now.strftime("%d %m %y %H:%M:%S %z")}\01"
      
      when :PING
        send_notice @msg.nick, "\01PING #{$2}\01"
      
      when :CLIENTINFO
        send_notice @msg.nick, "\01CLIENTINFO VERSION PING URL TIME\01"
      
      when :ACTION
        # Don't do anything!
  
      else
        send_notice @msg.nick, "\01ERRMSG #{$1} QUERY UNKNOWN\01"

      end

  end
end

