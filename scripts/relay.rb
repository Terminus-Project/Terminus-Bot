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

# TODO: Re-implement this whole crappy script.

def initialize
  register_script("Relay chat between two or more channels on one or more networks.")

  register_event(:PRIVMSG, :on_privmsg)
  register_event(:JOIN,    :on_join)
  register_event(:PART,    :on_part)
  register_event(:KICK,    :on_kick)
  register_event(:QUIT,    :on_quit)

  register_command("relay",  :cmd_relay,  5,  7, nil, "Manage channel relays. Parameters: ON|OFF source-network source-channel target-network target-channel")
  register_command("relays", :cmd_relays, 0,  7, nil, "List active channel relays.")

  @relays = get_data("relays", Array.new)
end

def cmd_relay(msg, params)
  source_network = params[1]
  source_channel = params[2]
  target_network = params[3]
  target_channel = params[4]
  
  return unless relay_points_exist?(msg, source_network, source_channel, target_network, target_channel)

  if params[0].upcase == "ON"

    if relay_exists?(source_network, source_channel, target_network, target_channel)
      msg.reply("That relay already exists.")
      return
    end

    @relays << [source_network, source_channel, target_network, target_channel]
    store_data("relays", @relays)

    msg.reply("Relay activated.")

  elsif params[0].upcase == "OFF"

    relay = relay_exists?(source_network, source_channel, target_network, target_channel)

    unless relay
      msg.reply("There is no matching relay.")
      return
    end

    @relays.delete(relay)
    store_data("relays", @relays)

    msg.reply("Relay deactivated.")

  else
    msg.reply("Unknown action. See \02HELP RELAY\02.")

  end

end

def cmd_relays(msg, params)
  if @relays.empty?
    msg.reply("There are no active relays.")
  else
    msg.reply(@relays.join(", "))
  end
end

def on_privmsg(msg)
  return unless msg.destination.start_with? "#"

  network = msg.connection.name
  channel = msg.destination

  matches = get_relays(network, channel)

  return if matches.empty?

  matches.each do |relay|
    if msg.text =~ /\01ACTION (.+)\01/

      if relay[0] == network and relay[1] == channel
        Bot::Connections[relay[2]].raw("PRIVMSG #{relay[3]} :\02[#{network}] * #{msg.nick}\02 #{$1}")
      else
        Bot::Connections[relay[0]].raw("PRIVMSG #{relay[1]} :\02[#{network}] * #{msg.nick}\02 #{$1}")
      end

    else

      if relay[0] == network and relay[1] == channel
        Bot::Connections[relay[2]].raw("PRIVMSG #{relay[3]} :[\02#{network}] <#{msg.nick}\02> #{msg.text}")
      else
        Bot::Connections[relay[0]].raw("PRIVMSG #{relay[1]} :[\02#{network}] <#{msg.nick}\02> #{msg.text}")
      end

    end
  end
end

def on_join(msg)
  return unless msg.text.start_with? "#"

  network = msg.connection.name
  channel = msg.text

  matches = get_relays(network, channel)

  return if matches.empty?

  matches.each do |relay|
    if relay[0] == network and relay[1] == channel
      Bot::Connections[relay[2]].raw("PRIVMSG #{relay[3]} :\02[#{network}]\02 --> \02#{msg.nick}\02 has joined \02#{channel}\02")
    else
      Bot::Connections[relay[0]].raw("PRIVMSG #{relay[1]} :\02[#{network}]\02 --> \02#{msg.nick}\02 has joined \02#{channel}\02")
    end
  end
end

def on_part(msg)
  return unless msg.destination.start_with? "#"

  network = msg.connection.name
  channel = msg.destination

  matches = get_relays(network, channel)

  return if matches.empty?

  matches.each do |relay|
    if relay[0] == network and relay[1] == channel
      Bot::Connections[relay[2]].raw("PRIVMSG #{relay[3]} :\02[#{network}]\02 <-- \02#{msg.nick}\02 has left \02#{channel}\02")
    else
      Bot::Connections[relay[0]].raw("PRIVMSG #{relay[1]} :\02[#{network}]\02 <-- \02#{msg.nick}\02 has left \02#{channel}\02")
    end
  end
end

def on_kick(msg)
  return unless msg.destination.start_with? "#"

  network = msg.connection.name
  channel = msg.destination

  matches = get_relays(network, channel)

  return if matches.empty?

  matches.each do |relay|
    if relay[0] == network and relay[1] == channel
      Bot::Connections[relay[2]].raw("PRIVMSG #{relay[3]} :\02[#{network}]\02 <-- \02#{msg.raw_arr[3]}\02 has been kicked from \02#{channel}\02 by \02#{msg.nick}\02 (#{msg.text})")
    else
      Bot::Connections[relay[0]].raw("PRIVMSG #{relay[1]} :\02[#{network}]\02 <-- \02#{msg.raw_arr[3]}\02 has been kicked from \02#{channel}\02 by \02#{msg.nick}\02 (#{msg.text})")
    end
  end
end

def on_quit(msg)
  network = msg.connection.name
  channel = ""
  matches = nil

  msg.connection.channels.each_value do |chan|

    if chan.get_user(msg.nick)
      channel = chan.name
      matches = get_relays(network, chan.name)
    end

  end

  return if matches == nil
  return if matches.empty?

  matches.each do |relay|
    if relay[0] == network and relay[1] == channel
      Bot::Connections[relay[2]].raw("PRIVMSG #{relay[3]} :\02[#{network}]\02 <-- \02#{msg.nick}\02 has quit (#{msg.text})")
    else
      Bot::Connections[relay[0]].raw("PRIVMSG #{relay[1]} :\02[#{network}]\02 <-- \02#{msg.nick}\02 has quit (#{msg.text})")
    end
  end
end

def get_relays(network, channel)
  matches = Array.new

  @relays.each do |relay|
    if (relay[0] == network and
      relay[1] == channel) or
      (relay[2] == network and
      relay[3] == channel)
      matches << relay
    end
  end

  return matches
end
def relay_exists?(source_network, source_channel, target_network, target_channel)
  @relays.each do |relay|
    if relay[0] == source_network and
      relay[1] == source_channel and
      relay[2] == target_network and
      relay[3] == target_channel
      return relay
    end
  end

  return false
end

def relay_points_exist?(msg, source_network, source_channel, target_network, target_channel)
  unless Bot::Connections.has_key? source_network
    msg.reply("Source network \02#{source_network}\02 does not exist.")
    return false
  end

  unless Bot::Connections.has_key? target_network
    msg.reply("Target network \02#{target_network}\02 does not exist.")
    return false
  end

  unless Bot::Connections[source_network].channels.has_key? source_channel
    msg.reply("Source channel \02#{source_channel}\02 does not exist.")
    return false
  end

  unless Bot::Connections[target_network].channels.has_key? target_channel
    msg.reply("Target channel \02#{target_channel}\02 does not exist.")
    return false
  end


  return true
end
