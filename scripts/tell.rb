
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
  register_script("Leave messages for inactive users.")

  register_event("PRIVMSG", :on_privmsg)

  register_command("tell",  :cmd_tell,  2,  0, nil, "Have me tell the given user something the next time they speak. Parameters: nick message")
end

def on_privmsg(msg)
  tells = get_data(msg.connection.name, Hash.new)

  return unless tells.has_key? msg.nick_canon

  tells[msg.nick_canon].each do |tell|
    time = Time.at(tell[0]).strftime("%Y-%m-%d %H:%M:%S %Z")

    msg.reply("Tell from \02#{tell[1]}\02 (#{time}): #{tell[2]}")
  end
  
  tells.delete(msg.nick_canon)
end

def cmd_tell(msg, params)
  tells = get_data(msg.connection.name, Hash.new)

  dest = msg.connection.canonize params[0]
  
  if tells.has_key? dest
    if tells[dest].length > get_config("max", 5).to_i
      msg.reply("No more tells can be left for that nick.")
      return
    end
  else
    tells[dest] = Array.new
  end

  tells[dest] << [Time.now.to_i, msg.nick, params[1]]

  store_data(msg.connection.name, tells)

  $log.info("tell.cmd_tell") { "Added: #{tells[dest]}" }

  msg.reply("I will try to deliver your message.")
end
