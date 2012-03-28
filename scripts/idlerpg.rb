
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

require "uri"
require 'net/http'
require 'rexml/document'
require 'htmlentities'

def initialize
  register_script("Play IdleRPG.")

  register_command("idlerpg", :cmd_idlerpg, 0, 0, "Get information about this network's IdleRPG. Parameters: [player]")

  register_event("JOIN", :on_join)
end

def cmd_idlerpg(msg, params)
  config = get_config(msg.connection.name)

  if config == nil
    msg.reply("I am not configured for this network's IdleRPG.")
    return
  end

  name = params.empty? ? msg.nick : params[0]

  unless config.has_key? "xml_url"
    msg.reply("I don't know where to get player info on this network.")
    return
  end

  info = get_player_info(name, config)

  if info == nil
    msg.reply("Player info not found.")
    return
  end

  msg.reply(info)
end

def get_player_info(player, config)
  url = "#{config["xml_url"]}#{URI.escape(player)}"

  body = Net::HTTP.get URI.parse(url)
  root = (REXML::Document.new(body)).root

  return nil if root == nil
  
  level = root.elements["//level"].text
  ttl = root.elements["//ttl"].text.to_i
  idled = root.elements["//totalidled"].text.to_i
  klass = root.elements["//class"].text

  return nil if level == nil or level.empty?

  ttl = Time.at(Time.now.to_i + ttl).to_duration_s
  idled = Time.at(Time.now.to_i + idled).to_duration_s

  "\02Level:\02 #{level} \02Class\02: #{klass} \02Time to Level:\02 #{ttl} \02Time Idled:\02 #{idled}"
end

def on_join(msg)
  config = get_config(msg.connection.name)

  return if config == nil

  return unless config["channel"].downcase == msg.destination.downcase

  return unless config.has_key? "login_command" and config.has_key? "nick"

  return if not msg.me? or not msg.nick != config["nick"]

  msg.send_privmsg(config["nick"], config["login_command"])
end

