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

register "Announce away status when away users are highlighted."

@@pending = {}

# Chop up an incoming message and see if it contains a nick that is
# in the channel. If it does, check for away status.
event :PRIVMSG do
  next if query? or not get_data([@connection.name, @msg.destination], false)

  # TODO: This is going to fail for nicks that end with punctuation. Do it a
  # different way.
  @msg.text.split(" ").each do |word|
    word.sub! /[[:punct:]]*\Z/, ""

    if channel.users.has_key? word
      check_away word
    end
  end
end

# We got a 301 (away status in WHOIS reply). Announce it if we
# should.
event :"301" do
  next unless @@pending.has_key? msg.raw_arr[3]
  
  dat = @@pending[@msg.raw_arr[3]]
  @@pending.delete @msg.raw_arr[3] # Delete it immediately so we never end up
                                 # with duplicate reports (that can happen
                                 # due to an unrelated bug).

  send_privmsg dat[1], "\02#{@msg.raw_arr[3]} is away:\02 #{@msg.text}"
end

# End of WHOIS! If we have a pending request for this nick, remove it.

event :"318" do
  @@pending.delete @msg.raw_arr[3] if @@pending.has_key? @msg.raw_arr[3]
end

command 'away', 'Enable or disable away status announcements for the current channel. Parameters: ON|OFF' do
  half_op! and channel! and argc! 1

  case @params.first.downcase

  when "on"
    store_data [@connection.name, @msg.destination], true

    reply "Away status announcement enabled for \02#{@msg.destination}\02."

  when "off"
    store_data [@connection.name, @msg.destination], false

    reply "Away status announcement disabled for \02#{@msg.destination}\02."

  end
end


helpers do

  # Send a WHOIS if we haven't in the last 30 seconds, and add the
  # request to our pending list.
  def check_away nick
    now = Time.now.to_i

    if @@pending.has_key? nick
      return if now - @@pending[nick][0] < 30
    end

    @@pending[nick] = [now, @msg.destination]

    send_whois nick
  end

end

# vim: set tabstop=2 expandtab:
