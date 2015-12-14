#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

# XXX optionally use http_client module

register 'Play IdleRPG.'

command 'idlerpg', 'Get information about players on this network\'s IdleRPG game. Parameters: [player]' do
  config = get_config @connection.name.to_sym

  if config.nil?
    raise "I am not configured for this network's IdleRPG."
  end

  name = @params.empty? ? @msg.nick : @params[0]

  unless config.key? :xml_url
    raise "I don't know where to get player info on this network."
  end

  reply get_player_info(name, config)
end

event :JOIN do
  config = get_config @connection.name.to_sym

  next if config.nil?

  next unless config[:channel].downcase == @msg.destination.downcase

  next unless config.key? :login_command and config.key? :nick

  next if not @msg.me? or not @msg.nick != config[:nick]

  send_privmsg config[:nick], config[:login_command]
end

helpers do
  def get_player_info player, config
    url = "#{config[:xml_url]}#{URI.escape(player)}"

    body = Net::HTTP.get URI.parse url
    root = (REXML::Document.new(body)).root

    raise 'Player info not found.' if root.nil?

    level = root.elements["//level"].text
    ttl   = root.elements["//ttl"].text.to_i
    idled = root.elements["//totalidled"].text.to_i
    klass = root.elements["//class"].text
    rank  = root.elements["//rank"].text unless root.elements["//rank"].nil? # Not available on all most networks

    raise 'Player info not found.' if level.nil? or level.empty?

    ttl   = Time.at(Time.now.to_i + ttl).to_duration_s
    idled = Time.at(Time.now.to_i + idled).to_duration_s

    data = {
      'Level'         => level,
      'Rank'          => rank,
      'Class'         => klass,
      'Time to Level' => ttl,
      'Time Idled'    => idled
    }

    data.delete('Rank') if data['Rank'].nil?

    data
  end
end

# vim: set tabstop=2 expandtab:
