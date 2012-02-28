
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
  register_script("Play IdleRPG.")

  register_command("idlerpg", :cmd_idlerpg, 0, 5, "Get information about the IdleRPG configuration for this network")

  register_event("JOIN", :on_join)
end

def cmd_idlerpg(msg, params)
  idleinfo = get_config(msg.connection.name)

  if idleinfo == nil
    msg.reply("I am not configured to play IdleRPG on this network.")
    return
  end

  bot, chan, login = idleinfo.split(/,/, 3)
  msg.reply("\02IdleRPG bot:\02 #{bot} \02Channel:\02 #{chan}. I will begin playing when I have joined the channel", false)
end

def on_join(msg)
  return unless msg.me?
  
  idleinfo = get_config(msg.connection.name, nil)
  return if idleinfo == nil

  bot, chan, login = idleinfo.split(/,/, 3)

  return unless chan.downcase == msg.destination.downcase

  msg.raw("PRIVMSG #{bot} :#{login}")
end

