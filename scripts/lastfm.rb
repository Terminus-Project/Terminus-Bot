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

# TODO: Store account names on bot accounts and use those if available.

raise "lastfm script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Last.fm interface.'

command 'np', 'Show the currently playing track for the given Last.fm user.' do
  argc! 1

  api_call(:user => @params.first, :method => "user.getrecenttracks", :limit => "1") do |root|
    raise "API call failed" if root == nil

    track = root.elements["//track"]

    if track == nil
      reply "No such user."
      next
    end

    if track.attributes.get_attribute("nowplaying") == nil
      reply "No music is currently playing."
      next
    end

    name = track.elements["//name"].text
    artist = track.elements["//artist"].text

    reply "\02#{@params.first} is listening to:\02 #{artist} - #{name}", false
  end
end

helpers do
  def api_call opt = {}
    api_url = 'http://ws.audioscrobbler.com/2.0/'

    api_key = get_config :apikey, nil

    if api_key == nil
      reply "A Last.fm API key must be set in the bot's configuration for this command to work."
      return
    end

    opt[:api_key] = api_key

    Bot.http_get(URI(api_url), opt) do |response|
      # TODO: Figure out why we never get here.

      unless response.status == 200
        reply "There was a problem retrieving information."
      else
        yield REXML::Document.new response.content.force_encoding('ASCII-8BIT')
      end
    end
  end
end

