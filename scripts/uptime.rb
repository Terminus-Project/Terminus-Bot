#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Show bot uptime and usage information.'

command 'uptime', 'Show how long the bot has been active.' do
  ctime         = File.ctime PID_FILE
  ctime_seconds = Time.now.to_i - ctime.to_i
  since         = ctime.to_duration_s

  lines_received, lines_sent = 0, 0
  bytes_received, bytes_sent = 0, 0

  Bot::Connections.each_value do |connection|
    lines_received += connection.lines_received
    bytes_received += connection.bytes_received
    lines_sent     += connection.lines_sent
    bytes_sent     += connection.bytes_sent
  end

  received_speed = bytes_received / ctime_seconds
  sent_speed     = bytes_sent / ctime_seconds

  reply 'Started' => "#{since} ago",
    'Received'  => "#{lines_received} lines, #{bytes_received.format_bytesize} (#{received_speed.format_bytesize}/second)",
    'Sent'      => "#{lines_sent} lines, #{bytes_sent.format_bytesize} (#{sent_speed.format_bytesize}/second)"

end

# vim: set tabstop=2 expandtab:
