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

register 'Manage the list of channels the bot occupies.'

@@canonized = Hash.new false

# TODO: All channel names in here need to use proper casemapping.
# TODO: Handle 405?

event :"001" do
  join_channels
end

event :JOIN do
  next unless get_config :antiforce, false or me?

  channels = get_data @connection.name, {}
  channel  = @connection.canonize @msg.destination

  # Are we configured to be in this channel?
  next if channels.has_key? channel
 
  $log.debug("channels.on_join") { "Parting channel #{@msg.destination} since we are not configured to be in it." }

  # It doesn't look like we should be here. Part!
  raw "PART #{@msg.destination} :I am not configured to be in this channel."
end

event :PING do
  leave_channels
  join_channels
end

helpers do

  def leave_channels
    channels = get_data @connection.name, {}

    @connection.channels.each_key do |chan|
      next if channels.has_key? chan

      raw "PART #{chan} :I am not configured to be in this channel."
    end
  end

  def join_channels
    chans, keys = [], []
    channels = get_data @connection.name, {}

    channels.each_pair do |channel, key|
      next if @connection.channels.has_key? channel

      chans << channel
      keys << (key.empty? ? "x" : key)

      # TODO: determine a sane maximum for this
      if chans.length == 4
        raw "JOIN #{chans.join(",")} #{keys.join(",")}"
        chans.clear
        keys.clear
      end
    end

    raw "JOIN #{chans.join(",")} #{keys.join(",")}" unless chans.empty?
  end 

end

command 'joinchans', 'Force the join channels event.' do
  level! 10

  join_channels
  reply "Done"
end

command 'join', 'Join a channel with optional key.' do
  level! 8

  arr = @params.first.split /\s+/, 2

  name = @connection.canonize arr[0]
  key  = arr.length == 2 ? arr[1] : ""

  # TODO: Use CHANTYPES
  unless name.start_with? "#" or name.start_with? "&"
    raise "That does not look like a channel name."
  end

  channels = get_data @connection.name, {}

  channels[name] = key
  store_data @connection.name, channels

  raw "JOIN #{name} #{key}"
  reply "I have joined #{name}"
end

command 'part', 'Part a channel.' do
  level! 8

  name = @connection.canonize @params.first

  channels = get_data @connection.name, {}

  unless channels.has_key? name
    reply "I am not configured to join that channel, but I'll dispatch a PART for it just in case."
    raw "PART #{name} :Leaving channel at request of #{@msg.nick}"
    next
  end

  results = channels[name]
  channels.delete name

  store_data @connection.name, channels

  raw "PART #{name} :Leaving channel at request of #{@msg.nick}"
  reply "I have left #{name}"
end

command 'cycle', 'Part and then join a channel.' do
  level! 8

  channels = get_data @connection.name, {}

  name = @connection.canonize @params.first

  next unless channels.has_key? name
  
  raw "PART #{name} :Be right back!"
  raw "JOIN #{name}"
end

