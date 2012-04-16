
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

def initialize
  register_script("Manage the list of channels the bot occupies.")

  register_command("joinchans", :cmd_joinchans, 0,  10, nil, "Force the join channels event.")
  register_command("join",      :cmd_join,      1,  5,  nil, "Join a channel with optional key.")
  register_command("part",      :cmd_part,      1,  5,  nil, "Part a channel.")
  register_command("cycle",     :cmd_cycle,     1,  5,  nil, "Part and then join a channel.")

  register_event("001",   :join_channels)
  register_event("JOIN",  :on_join)
  register_event("PING",  :leave_channels)
  register_event("PING",  :join_channels)

  data = get_all_data

  # Code to convert old channel database entries to the new style.
  # TODO: Remove this at some point.

  return if data.empty?

  return if data[0].is_a? Array

  data.each_pair do |server, channels|
    new_channels = []

    channels.each do |channel|
      new_channels << [channel, ""]
    end

    store_data(server, new_channels)
  end


  # TODO: Handle 405?
end

def join_channels(msg)
  chans, keys = [], []
  channels = get_data(msg.connection.name, Array.new)

  channels.uniq!

  # TODO: Don't join channels we are already in!
  channels.each do |channel|
    chans << channel[0]
    keys << channel[1]

    # TODO: determine a sane maximum for this
    if chans.length == 4
      msg.raw("JOIN #{chans.join(",")} #{keys.join(",")}")
      chans.clear
      keys.clear
    end
  end

  msg.raw("JOIN #{chans.join(",")} #{keys.join(",")}") unless chans.empty?

  # Just in case uniq! got rid of dupes
  store_data(msg.connection.name, channels)
end

def on_join(msg)
  # Are we enabled?
  return unless get_config("antiforce", false)

  # Are we the ones joining?
  return unless msg.me?

  channels = get_data(msg.connection.name, Array.new)

  # Are we configured to be in this channel?
  return unless (channels.select {|c| c[0] == msg.destination.downcase }).empty?
 
  $log.debug("channels.on_join") { "Parting channel #{msg.destination} since we are not configured to be in it." }

  # It doesn't look like we should be here. Part!
  msg.raw("PART #{msg.destination} :I am not configured to be in this channel.") 
end

def leave_channels(msg)
  channels = get_data(msg.connection.name, Array.new)

  msg.channels.each_key do |chan|
    next if (channels.select {|c| c[0] == msg.destination.downcase }).empty?

    msg.raw("PART #{chan} :I am not configured to be in this channel.") 
  end
end

def cmd_joinchans(msg, params)
  join_channels(msg)
  msg.reply("Done")
end

def cmd_join(msg, params)
  name = params[0].downcase

  unless name.start_with? "#" or name.start_with? "&"
    msg.reply("That does not look like a channel name.")
    return
  end

  channels = get_data(msg.connection.name, Array.new)

  channels << [name, "x"] if (channels.select {|c| c[0] == msg.destination.downcase }).empty?
  store_data(msg.connection.name, channels)

  msg.raw("JOIN #{name}")
  msg.reply("I have joined #{name}")
end

def cmd_part(msg, params)
  name = params[0].downcase
  channels = get_data(msg.connection.name, Array.new)

  results = channels.select {|c| c[0] == name }

  if results.empty?
    msg.reply("I am not configured to join that channel, but I'll dispatch a PART for it just in case.")
    msg.raw("PART #{name} :Leaving channel at request of #{msg.nick}")
    return
  end

  channels.delete(results[0])

  store_data(msg.connection.name, channels)

  msg.raw("PART #{name} :Leaving channel at request of #{msg.nick}")
  msg.reply("I have left #{name}")
end

def cmd_cycle(msg, params)
  msg.raw("PART #{params[0]} :Be right back!")
  msg.raw("JOIN #{params[0]}")
end
