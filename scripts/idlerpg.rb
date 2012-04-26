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

require "uri"
require 'net/http'
require 'rexml/document'
require 'htmlentities'

def initialize
  register_script("Play IdleRPG.")

  register_command("idlerpg", :cmd_idlerpg, 0, 0, nil, "Get information about this network's IdleRPG. Parameters: [player]")

  register_event(:JOIN, :on_join)
end

def cmd_idlerpg(msg, params)
  config = get_config(msg.connection.name.to_sym)

  if config == nil
    msg.reply("I am not configured for this network's IdleRPG.")
    return
  end

  name = params.empty? ? msg.nick : params[0]

  unless config.has_key? :xml_url
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
  url = "#{config[:xml_url]}#{URI.escape(player)}"

  body = Net::HTTP.get URI.parse(url)
  root = (REXML::Document.new(body)).root

  return nil if root == nil
  
  level = root.elements["//level"].text
  ttl = root.elements["//ttl"].text.to_i
  idled = root.elements["//totalidled"].text.to_i
  klass = root.elements["//class"].text
  rank = root.elements["//rank"].text # Not available on all most networks

  return nil if level == nil or level.empty?

  ttl = Time.at(Time.now.to_i + ttl).to_duration_s
  idled = Time.at(Time.now.to_i + idled).to_duration_s

  buf =  "\02Level:\02 #{level}"
  buf << " \02Rank:\02 #{rank}" if rank != nil and not rank.empty?
  buf << " \02Class:\02 #{klass}"
  buf << " \02Time to Level:\02 #{ttl}"
  buf << " \02Time Idled:\02 #{idled}"
end

def on_join(msg)
  config = get_config(msg.connection.name.to_sym)

  return if config == nil

  return unless config[:channel].downcase == msg.destination.downcase

  return unless config.has_key? :login_command and config.has_key? :nick

  return if not msg.me? or not msg.nick != config[:nick]

  msg.send_privmsg(config[:nick], config[:login_command])
end

