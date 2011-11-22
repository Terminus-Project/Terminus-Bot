
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
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

  register_event("376", :join_channels)

  @channels = get_data("channels", Hash.new)
end

def die
  unregister_script
  unregister_commands
  unregister_events
end

def join_channels(msg)
  # TODO: Join many channels at once.

  if @channels.has_key? msg.connection.name
    @channels[msg.connection.name].each do |channel|
      msg.raw("JOIN #{channel}")
    end
  else
    @channels[msg.connection.name] = Array.new
  end
end

def cmd_join(msg, params)
  msg.raw("JOIN #{params[0]}")

  @channels[msg.connection.name] << params[0]

  store_data("channels", @channels)
end

def cmd_part(msg, params)
  msg.raw("PART #{params[0]} :Leaving channel at request of #{msg.nick}")

  @channels[msg.connection.name].delete(params[0])

  store_data("channels", @channels)
end
