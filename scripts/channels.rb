
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

  @channels = get_data("channels", Hash.new)
end

def die
  unregister_script
  unregister_commands
  unregister_events
end

def join_channels(msg)
  buf = Array.new

  if @channels.has_key? msg.connection.name
    @channels[msg.connection.name].each do |channel|
      buf << channel

      # TODO: determine a sane maximum for this
      if buf.length == 4
        msg.raw("JOIN #{buf.join(",")}")
        buf.clear
      end
    end

    msg.raw("JOIN #{buf.join(",")}") unless buf.empty?
  else
    @channels[msg.connection.name] = Array.new
  end
end

def on_join(msg)
  # Are we enabled?
  return unless get_config("antiforce", false)

  # Are we the ones joining?
  return unless msg.nick == msg.connection.nick

  # Are we configured to be in this channel?
  return if @channels[msg.connection.name].include? msg.text
 
  $log.debug("channels.on_join") { "Parting channel #{msg.text} since we are not configured to be in it." }

  # It doesn't look like we should be here. Part!
  msg.raw("PART #{msg.text} :I am not configured to be in this channel.") 
end

def leave_channels(msg)
  msg.channels.each_key do |chan|
    next if @channels[msg.connection.name].include? chan
    
    msg.raw("PART #{chan} :I am not configured to be in this channel.") 
  end
end

def cmd_join(msg, params)
  @channels[msg.connection.name] << params[0]
  msg.raw("JOIN #{params[0]}")

  store_data("channels", @channels)
end

def cmd_part(msg, params)
  @channels[msg.connection.name].delete(params[0])
  msg.raw("PART #{params[0]} :Leaving channel at request of #{msg.nick}")

  store_data("channels", @channels)
end
