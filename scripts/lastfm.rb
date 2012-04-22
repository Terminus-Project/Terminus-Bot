
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

URL='https://ws.audioscrobbler.com/2.0/'

def initialize
  register_script("Last.fm interface.")

  register_command("np",    :cmd_np,    1,  0, nil, "Show the most recent track for the given Last.fm user.")
end

def api_call(msg, opt = {})
  api_key = get_config("apikey", nil)

  if api_key == nil
    msg.reply("A Last.fm API key must be set in the bot's configuration for this command to work.")
    return  
  end

  url = "#{URL}?api_key=" << URI.escape(api_key)

  opt.each do |k, v|
    url << "&" << k.to_s << "=" << URI.escape(v.to_s)
  end

  $log.debug("lastfm.api_call") { url }

  uri = URI(url)

  response = Net::HTTP.start(uri.host, uri.port,
                             :use_ssl => uri.scheme == "https",
                             :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
    http.request Net::HTTP::Get.new(uri.request_uri)
  end

  case response

  when Net::HTTPSuccess
    return REXML::Document.new(response.body.force_encoding('UTF-8'))

  else
    msg.reply("There was a problem retrieving information. (Response code: #{response.code})")

  end

  nil
end


def cmd_np(msg, params)
  root = api_call(msg, :user => params[0], :method => "user.getrecenttracks", :limit => 1)

  return if root == nil

  track = root.elements["//track"]

  if track == nil
    msg.reply("No such user.")
    return
  end

  if track.attributes.get_attribute("nowplaying") == nil
    msg.reply("No music is currently playing.")
    return
  end

  name = track.elements["//name"].text
  artist = track.elements["//artist"].text

  msg.reply("\02#{params[0]} is listening to:\02 #{artist} - #{name}", false)

end

