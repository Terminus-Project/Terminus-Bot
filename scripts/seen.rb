
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
#

def initialize
  register_script("Tracks when a user is last seen speaking.")

  register_command("seen", :cmd_seen, 1, 0, "Check when the given user was last seen \02speaking\02 on IRC.")

  register_event("PRIVMSG", :on_message)
end

def on_message(msg)
  return unless msg.destination.start_with? "#" or msg.destination.start_with? "&"

  # This whole process is a bit expensive. Should store
  # this stuff in class instance variables?

  seen_nicks = get_data(msg.connection.name, Hash.new)

  if msg.text =~ /\01ACTION (.+)\01/
    seen_nicks[msg.nickcanon] = [Time.now.to_i, $1]

  elsif msg.text.include? "\01"
    # Don't record CTCPs that aren't ACTIONs.
    return

  else
    seen_nicks[msg.nickcanon] = [Time.now.to_i, msg.text]

  end

  store_data(msg.connection.name, seen_nicks)
end

def cmd_seen(msg, params)
  nick = msg.connection.canonize params[0]

  if msg.nickcanon == nick
    msg.reply("That's you, silly!")
    return
  end

  seen_nicks = get_data(msg.connection.name, Hash.new)

  unless seen_nicks.has_key? nick
    msg.reply("I have not seen \02#{nick}\02.")
    return
  end

  seen_nick = seen_nicks[nick]

  time = Time.at(seen_nick[0]).to_duration_s

  msg.reply("\02#{params[0]}\02 was last seen \02#{time} ago\02: <#{params[0]}> #{seen_nick[1]}")
end
