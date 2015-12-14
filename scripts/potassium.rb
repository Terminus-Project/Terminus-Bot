#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Track user potassium.'

command 'potassium', 'Check potassium for yourself or the specified nick.' do
  target = @params.empty? ? @msg.nick : @params.first.strip

  reply "#{target} has #{get_k target} potassium"
end

command 'hyperkalaemia', 'Find out who has the most severe hyperkalaemia.' do
  reply top
end

command 'hypokalaemia', 'Find out who was the most severe hypokalaemia.' do
  reply bottom
end

# TODO: use regex handler?
event :PRIVMSG do
  next if query?

  add_k @msg.nick_canon, @msg.text.split.count {|w| w =~ /^[Kk]$/}
end

helpers do

  def top n = 3
    potassium = get_data(@connection.name, Hash.new(0)).sort_by {|_, k| k}

    raise 'Nobody has any potassium, yet.' if potassium.empty?

    Hash[potassium.last(n).reverse]
  end

  def bottom n = 3
    potassium = get_data(@connection.name, Hash.new(0)).sort_by {|_, k| k}

    raise 'Nobody has any potassium, yet.' if potassium.empty?

    Hash[potassium.first(n).reverse]
  end

  def get_k nick
    get_data(@connection.name, Hash.new(0))[@connection.canonize nick] || 0
  end

  def add_k nick, amount = 1
    return if amount.zero?

    potassium = get_data @connection.name, Hash.new(0)

    # here to fix something... this will be removed eventually
    potassium[nick] = 0  if potassium[nick].nil?

    potassium[nick] += amount

    $log.debug('potassium.add_k') { "#{nick} potassium change: #{amount}: #{potassium[nick]}" }

    store_data @connection.name, potassium
  end

end

# vim: set tabstop=2 expandtab:
