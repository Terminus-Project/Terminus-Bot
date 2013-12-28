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

register 'Track user karma.'

command 'karma', 'Check karma for yourself or the specified nick.' do
  target = @params.empty? ? @msg.nick : @params.first.strip

  reply "#{target}'s karma is #{get_karma target}"
end

command 'popular', 'Find out who has the highest karma.' do
  reply top
end

command 'unpopular', 'Find out who was the lowest karma.' do
  reply bottom
end

event :PRIVMSG do
  next if query?

  match = @msg.text.match(/^(?<target>\S+)(?<change>\+\+|--)(\s|,|;|$)/)

  next unless match

  target = match[:target]

  if match[:change] == '++'
    add_karma target
  else
    subtract_karma target
  end
end

helpers do

  def top n = 3
    karma = get_data(@connection.name, Hash.new(0)).sort_by {|n, k| k}

    if karma.empty?
      return 'Nobody has received karma, yet.'
    end

    Hash[karma.last(n).reverse]
  end

  def bottom n = 3
    karma = get_data(@connection.name, Hash.new(0)).sort_by {|n, k| k}

    if karma.empty?
      return 'Nobody has received karma, yet.'
    end

    Hash[karma.first(n).reverse]
  end

  def get_karma nick
    get_data(@connection.name, Hash.new(0)).fetch @connection.canonize(nick), 0
  end

  def add_karma nick, amount = 1
    unless channel.users.has_key? nick
      $log.debug('karma.add_karma') { "Skipping nonexistent target #{nick}" }
      return
    end

    nick = @connection.canonize nick

    if @msg.nick_canon == nick
      $log.debug('karma.add_karma') { "Skipping self karma change attempt for #{nick}" }
      return
    end

    karma = get_data @connection.name, Hash.new(0)

    # I screwed something up, so now we have to do this for now. Oops.
    karma[nick] = 0 if karma[nick].nil?

    karma[nick] += amount

    $log.debug('karma.add_karma') { "#{nick} karma change: #{amount}: #{karma[nick]}" }

    store_data @connection.name, karma
  end

  def subtract_karma nick
    add_karma nick, -1
  end

end
# vim: set tabstop=2 expandtab:
