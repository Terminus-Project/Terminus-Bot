
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
  register_script("Announce away status when away users are highlighted.")

  register_command("away", :cmd_away,  1,  1, "Enable or disable away status announcements for the current channel. Parameters: ON|OFF")

  register_event("PRIVMSG", :on_privmsg)
  register_event("301",     :on_away)
  register_event("318",     :on_whois_end)

  @pending = Hash.new
end

def die
  unregister_script
  unregister_commands
  unregister_events
end

# Chop up an incoming message and see if it contains a nick that is
# in the channel. If it does, check for away status.
def on_privmsg(msg)
  return if msg.private? or msg.silent? or not get_data(msg.connection.name + "." + msg.destination, false)

  chan = msg.connection.channels[msg.destination]

  msg.text.split(" ").each do |word|
    word.sub!(/[,:.;]+\Z/, "")

    if chan.get_user(word)
      check_away(msg, word)
    end
  end
end

# Send a WHOIS if we haven't in the last 30 seconds, and add the
# request to our pending list.
def check_away(msg, nick)
  now = Time.now.to_i

  if @pending.has_key? nick
    return if now - @pending[nick][0] < 30
  end

  @pending[nick] = [now, msg.destination]

  msg.raw("WHOIS #{nick}")
end

# We got a 301 (away status in WHOIS reply). Announce it if we
# should.
def on_away(msg)
  return unless @pending.has_key? msg.raw_arr[3]
  
  dat = @pending[msg.raw_arr[3]]
  @pending.delete(msg.raw_arr[3]) # Delete it immediately so we never end up
                                  # with duplicate reports (that can happen
                                  # due to an unrelated bug).

  msg.raw("PRIVMSG #{dat[1]} :\02#{msg.raw_arr[3]} is away:\02 #{msg.text}")
end

# End of WHOIS! If we have a pending request for this nick, remove it.
def on_whois_end(msg)
  @pending.delete(msg.raw_arr[3]) if @pending.has_key? msg.raw_arr[3]
end

def cmd_away(msg, params)
  if msg.private?
    msg.reply("This command must be used in a channel.")
    return
  end

  case params[0].downcase

  when "on"
    store_data(msg.connection.name + "." + msg.destination, true)

    msg.reply("Away status announcement enabled for \02#{msg.destination}\02.")

  when "off"
    store_data(msg.connection.name + "." + msg.destination, false)

    msg.reply("Away status announcement disabled for \02#{msg.destination}\02.")

  end
end
