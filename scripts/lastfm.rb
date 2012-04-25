
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


require 'rexml/document'
require 'htmlentities'

URL='https://ws.audioscrobbler.com/2.0/'

def initialize
  raise "lastfm script requires the http module" unless defined? Bot.http_get

  register_script("Last.fm interface.")

  register_command("np",    :cmd_np,    1,  0, nil, "Show the most recent track for the given Last.fm user.")
end

def api_call(msg, opt = {})
  api_key = get_config(:apikey, nil)

  if api_key == nil
    msg.reply("A Last.fm API key must be set in the bot's configuration for this command to work.")
    return nil
  end

  # TODO: Build this as a URI object, not a string.
  url = "#{URL}?api_key=" << URI.escape(api_key)

  opt.each do |k, v|
    url << "&" << k.to_s << "=" << URI.escape(v.to_s)
  end

  $log.debug("lastfm.api_call") { url }

  response = Bot.http_get(URI(url))

  if response == nil
    msg.reply("There was a problem retrieving information. (Response code: #{response.code})")
    return nil
  end

  REXML::Document.new(response[:response].body.force_encoding('UTF-8'))
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

