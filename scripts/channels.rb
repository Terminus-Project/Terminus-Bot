
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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

  register_command("join", :cmd_join, 1,  5, "Join a channel.")
  register_command("part", :cmd_part, 1,  5, "Part a channel.")

  register_event("376",   :join_channels)
  register_event("JOIN",  :on_join)
  register_event("PING",  :leave_channels)

  # TODO: Handle 405?
end

def die
  unregister_script
  unregister_commands
  unregister_events
end

def join_channels(msg)
  buf = Array.new
  channels = get_data(msg.connection.name, Array.new)

  channels.uniq!

  channels.each do |channel|
    buf << channel

    # TODO: determine a sane maximum for this
    if buf.length == 4
      msg.raw("JOIN #{buf.join(",")}")
      buf.clear
    end
  end

  msg.raw("JOIN #{buf.join(",")}") unless buf.empty?

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
  return if channels.include? msg.destination
 
  $log.debug("channels.on_join") { "Parting channel #{msg.destination} since we are not configured to be in it." }

  # It doesn't look like we should be here. Part!
  msg.raw("PART #{msg.destination} :I am not configured to be in this channel.") 
end

def leave_channels(msg)
  channels = get_data(msg.connection.name, Array.new)

  msg.channels.each_key do |chan|
    next if channels.include? chan
    
    msg.raw("PART #{chan} :I am not configured to be in this channel.") 
  end
end

def cmd_join(msg, params)
  name = params[0].downcase

  unless name.start_with? "#" or name.start_with? "&"
    msg.reply("That does not look like a channel name.")
    return
  end

  channels = get_data(msg.connection.name, Array.new)

  channels << name unless channels.has_key? name
  store_data(msg.connection.name, channels)

  msg.raw("JOIN #{name}")
  msg.reply("I have joined #{name}")
end

def cmd_part(msg, params)
  name = params[0].downcase
  channels = get_data(msg.connection.name, Array.new)

  unless channels.has_key? name
    msg.reply("I am not configured to join that channel, but I'll dispatch a PART for it just in case.")
    msg.raw("PART #{name} :Leaving channel at request of #{msg.nick}")
    return
  end

  channels.delete(name)
  store_data(msg.connection.name, channels)

  msg.raw("PART #{name} :Leaving channel at request of #{msg.nick}")
  msg.reply("I have left #{name}")
end
