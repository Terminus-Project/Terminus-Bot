#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Leave messages for inactive users.'


event :PRIVMSG do
  tells = get_data @connection.name, Hash.new

  next unless tells.has_key? @msg.nick_canon

  tells[@msg.nick_canon].each do |tell|
    time = Time.at(tell[0]).strftime("%Y-%m-%d %H:%M:%S %Z")

    send_notice @msg.nick_canon, "Tell from \02#{tell[1]}\02 (#{time}): #{tell[2]}"
  end
  
  tells.delete @msg.nick_canon
end

command 'tell', 'Have the bot tell the given user something the next time they speak. Parameters: nick message' do
  argc! 2

  tells = get_data @connection.name, Hash.new

  dest = @connection.canonize @params.first

  if @connection.support('CHANTYPES', '#&').include? dest.chr
    raise "You cannot leave tells for channels."
  end

  if dest == @connection.canonize(@connection.nick)
    raise "You cannot leave tells for me."
  end

  if dest == @connection.canonize(@msg.nick)
    raise "You cannot leave tells for yourself."
  end
  
  if tells.has_key? dest
    if tells[dest].length > get_config(:max, 5).to_i
      raise "No more tells can be left for that nick."
    end
  else
    tells[dest] = []
  end

  tells[dest] << [Time.now.to_i, @msg.nick, @params[1]]

  store_data @connection.name, tells

  $log.info("tell.cmd_tell") { "Added: #{tells[dest]}" }

  reply "I will try to deliver your message."
end

