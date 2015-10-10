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

# TODO: Re-implement this whole crappy script.
# TODO: No, really. Needs to be redone or removed.

register 'Relay chat between two or more channels on one or more networks.'

@@relays = get_data "relays", Array.new

command 'relay', 'Manage channel relays. Parameters: ON|OFF source-network source-channel target-network target-channel' do
  level! 7 and argc! 5

  source_network = @params[1].to_sym
  source_channel = @params[2]
  target_network = @params[3].to_sym
  target_channel = @params[4]

  next unless relay_points_exist? source_network, source_channel, target_network, target_channel

  source_channel = Bot::Connections[source_network].canonize source_channel
  target_channel = Bot::Connections[target_network].canonize target_channel

  case @params.first.upcase
  when "ON"

    if relay_exists? source_network, source_channel, target_network, target_channel
      raise "That relay already exists."
    end

    @@relays << [source_network, source_channel, target_network, target_channel]
    store_data "relays", @@relays

    reply "Relay activated."

  when "OFF"

    relay = relay_exists? source_network, source_channel, target_network, target_channel

    unless relay
      raise "There is no matching relay."
    end

    @@relays.delete relay
    store_data "relays", @@relays

    reply "Relay deactivated."

  else
    raise "Unknown action. See \02HELP RELAY\02."

  end

end

command 'relays', 'List active channel relays.' do
  level! 7

  if @@relays.empty?
    reply "There are no active relays."
  else
    reply @@relays.join(", ")
  end
end

event :PRIVMSG do
  next unless channel?

  network = @connection.name
  channel = @msg.destination_canon
  channel_original = @msg.destination

  matches = get_relays network, channel

  next if matches.empty?

  matches.each do |relay|
    if @msg.text =~ /\01ACTION (.+)\01/

      if relay[0] == network and relay[1] == channel
        Bot::Connections[relay[2]].raw generate_raw(:action, relay[3], network,
          channel_original, @msg.nick_with_prefix(channel), $1)
      else
        Bot::Connections[relay[0]].raw generate_raw(:action, relay[1], network,
          channel_original, @msg.nick_with_prefix(channel), $1)
      end

    else

      if relay[0] == network and relay[1] == channel
        Bot::Connections[relay[2]].raw generate_raw(:message, relay[3], network,
          channel_original, @msg.nick_with_prefix(channel), @msg.text)
      else
        Bot::Connections[relay[0]].raw generate_raw(:message, relay[1], network,
          channel_original, @msg.nick_with_prefix(channel), @msg.text)
      end

    end
  end
end

event :JOIN do
  next unless channel?

  network = @connection.name
  channel = @msg.destination_canon
  channel_original = @msg.destination

  matches = get_relays network, channel

  next if matches.empty?

  matches.each do |relay|
    if relay[0] == network and relay[1] == channel
      Bot::Connections[relay[2]].raw generate_raw(:join, relay[3], network,
        channel_original, @msg.nick)
    else
      Bot::Connections[relay[0]].raw generate_raw(:join, relay[1], network,
        channel_original, @msg.nick)
    end
  end
end

event :PART do
  next unless channel?

  network = @connection.name
  channel = @msg.destination_canon
  channel_original = @msg.destination

  matches = get_relays network, channel

  next if matches.empty?

  matches.each do |relay|
    if relay[0] == network and relay[1] == channel
      Bot::Connections[relay[2]].raw generate_raw(:part, relay[3], network,
        channel_original, @msg.nick)
    else
      Bot::Connections[relay[0]].raw generate_raw(:part, relay[1], network,
        channel_original, @msg.nick)
    end
  end
end

event :KICK do
  next unless channel?

  network = @connection.name
  channel = @msg.destination_canon
  channel_original = @msg.destination

  matches = get_relays network, channel

  return if matches.empty?

  kicked, reason = @msg.parameters.split(/ :/, 2)

  matches.each do |relay|
    if relay[0] == network and relay[1] == channel
      Bot::Connections[relay[2]].raw generate_raw(:kick, relay[3], network,
        channel_original, @msg.nick_with_prefix(channel), reason, kicked)
    else
      Bot::Connections[relay[0]].raw generate_raw(:kick, relay[1], network,
        channel_original, @msg.nick_with_prefix(channel), reason, kicked)
    end
  end
end

event :QUIT_CHANNEL do
  network = @connection.name
  channel = @data[:channel].name_canon

  matches = get_relays network, channel

  next if matches.empty?

  matches.each do |relay|
    if relay[0] == network
      Bot::Connections[relay[2]].raw generate_raw(:quit, relay[3], network,
        channel, @msg.nick, @msg.text)
    else
      Bot::Connections[relay[0]].raw generate_raw(:quit, relay[1], network,
        channel, @msg.nick, @msg.text)
    end
  end
end

helpers do

  def generate_raw type, dest, network, channel, nick, text = '', misc = ''
    prefix = message_prefix network, channel
    case type
    when :message
      "PRIVMSG #{dest} :#{prefix} <\02#{nick}\02> #{text}"
    when :action
      "PRIVMSG #{dest} :#{prefix} * \02#{nick}\02 #{text}"
    when :join
      "PRIVMSG #{dest} :#{prefix} --> \02#{nick}\02 has joined \02#{channel}\02"
    when :part
      "PRIVMSG #{dest} :#{prefix} <-- \02#{nick}\02 has left \02#{channel}\02"
    when :kick
      "PRIVMSG #{dest} :#{prefix} <-- \02#{misc}\02 has has been kicked from \02#{channel}\02 by \02#{nick}\02 (#{text})"
    when :quit
      "PRIVMSG #{dest} :#{prefix} <-- \02#{nick}\02 has quit (#{text})"
    end
  end

  def message_prefix network, channel
    if get_config(:show_channel, true)
      "[\02#{network}:#{channel}\02]"
    else
      "[\02#{network}\02]"
    end
  end

  def get_relays network, channel
    matches = []

    @@relays.each do |relay|
      if (relay[0] == network and
          relay[1] == channel) or
          (relay[2] == network and
           relay[3] == channel)
           matches << relay
      end
    end

    matches
  end
  def relay_exists? source_network, source_channel, target_network, target_channel
    @@relays.each do |relay|
      if relay[0] == source_network and
        relay[1] == source_channel and
        relay[2] == target_network and
        relay[3] == target_channel
        return relay
      elsif relay[2] == source_network and
        relay[3] == source_channel and
        relay[0] == target_network and
        relay[1] == target_channel
        return relay
      end
    end

    false
  end

  def relay_points_exist? source_network, source_channel, target_network, target_channel
    unless Bot::Connections.has_key? source_network
      reply "Source network \02#{source_network}\02 does not exist."
      return false
    end

    unless Bot::Connections.has_key? target_network
      reply "Target network \02#{target_network}\02 does not exist."
      return false
    end

    source_channel = Bot::Connections[source_network].canonize source_channel

    unless Bot::Connections[source_network].channels.has_key? source_channel
      reply "Source channel \02#{source_channel}\02 does not exist."
      return false
    end

    target_channel = Bot::Connections[target_network].canonize target_channel

    unless Bot::Connections[target_network].channels.has_key? target_channel
      reply "Target channel \02#{target_channel}\02 does not exist."
      return false
    end

    true
  end
end
# vim: set tabstop=2 expandtab:
