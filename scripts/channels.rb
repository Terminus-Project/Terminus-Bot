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

register 'Manage the list of channels the bot occupies.'

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
  next if channels.key? channel

  $log.debug("channels.on_join") { "Parting channel #{@msg.destination} since we are not configured to be in it." }

  # It doesn't look like we should be here. Part!
  send_part @msg.destination, "I am not configured to be in this channel."
end

event :periodic do
  leave_channels
  join_channels
end

helpers do

  def leave_channels
    Bot::Connections.each do |name, connection|
      channels = get_data name, {}

      connection.channels.each_key do |chan|
        next if channels.key? chan

        connection.send_part chan, "I am not configured to be in this channel."
      end
    end
  end

  def join_channels
    Bot::Connections.each do |name, connection|
      connection.send_join get_data(name, {})
    end
  end

end

command 'joinchans', 'Force the join channels event.' do
  level! 10

  join_channels
  reply "Done"
end

command 'join', 'Join a channel with optional key.' do
  level! 8
  argc! 1

  arr = @params.first.split(/\s+/, 2)

  name = @connection.canonize arr[0]
  key  = arr.length == 2 ? arr[1] : ""

  unless @connection.support('CHANTYPES', '#&').include? name.chr
    raise "That does not look like a channel name."
  end

  channels = get_data @connection.name, {}

  channels[name] = key
  store_data @connection.name, channels

  send_join "#{name} #{key}"
  reply "I have joined #{name}"
end

command 'part', 'Part a channel.' do
  level! 8
  if @params.empty?
    name = @msg.destination_canon
  else
    name = @connection.canonize @params.first
  end

  channels = get_data @connection.name, {}

  unless channels.key? name
    reply "I am not configured to join that channel, but I'll dispatch a PART for it just in case."
    raw "PART #{name} :Leaving channel at request of #{@msg.nick}"
    next
  end

  channels.delete name

  store_data @connection.name, channels

  send_part name, "Leaving channel at request of #{@msg.nick}"
  reply "I have left #{name}"
end

command 'cycle', 'Part and then join a channel.' do
  level! 8
  if @params.empty?
    name = @msg.destination_canon
  else
    name = @connection.canonize @params.first
  end

  channels = get_data @connection.name, {}

  next unless channels.key? name

  send_part name, "Be right back!"
  send_join name
end

# vim: set tabstop=2 expandtab:
