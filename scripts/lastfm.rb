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

URL='http://ws.audioscrobbler.com/2.0/'

def initialize
  raise "lastfm script requires the http_client module" unless defined? MODULE_LOADED_HTTP

  register_script("Last.fm interface.")

  register_command("np",    :cmd_np,    1,  0, nil, "Show the currently playing track for the given Last.fm user.")
end

def api_call(msg, opt = {})
  api_key = get_config(:apikey, nil)

  if api_key == nil
    msg.reply("A Last.fm API key must be set in the bot's configuration for this command to work.")
    yield nil
    return
  end

  opt[:api_key] = api_key
    
  Bot.http_get(URI(URL), opt) do |response|
    # TODO: Figure out why we never get here.

    unless response.status == 200
      msg.reply("There was a problem retrieving information.")
    else
      yield REXML::Document.new(response.content.force_encoding('ASCII-8BIT'))
    end
  end
end


def cmd_np(msg, params)
  api_call(msg, :user => params[0], :method => "user.getrecenttracks", :limit => "1") do |root|
    raise "API call failed" if root == nil

    track = root.elements["//track"]

    if track == nil
      msg.reply("No such user.")
      next
    end

    if track.attributes.get_attribute("nowplaying") == nil
      msg.reply("No music is currently playing.")
      next
    end

    name = track.elements["//name"].text
    artist = track.elements["//artist"].text

    msg.reply("\02#{params[0]} is listening to:\02 #{artist} - #{name}", false)
  end
end

