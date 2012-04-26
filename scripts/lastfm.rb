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

require 'rexml/document'
require 'htmlentities'

URL='https://ws.audioscrobbler.com/2.0/'

def initialize
  raise "lastfm script requires the http_client module" unless defined? Bot.http_get

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

