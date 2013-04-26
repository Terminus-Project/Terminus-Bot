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

require 'multi_json'
require 'htmlentities'

# TODO: Store account names on bot accounts and use those if available.

need_module! 'http'

register 'Last.fm interface.'

command 'np', 'Show the currently playing track for the given Last.fm user.' do
  argc! 1

  user = @params.first.strip

  opts = {
    :user   => user,
    :method => 'user.getrecenttracks',
    :limit  => 1
  }

  api_call opts do |json|
    unless json['recenttracks'] and json['recenttracks']['track']
      raise 'No recent tracks found.'
    end

    track = json['recenttracks']['track'].first

    # hax
    unless track.is_a? Hash and track['@attr'] and track['@attr']['nowplaying']
      reply 'No music is currently playing.'
      next
    end

    name   = track['name']
    artist = track['artist']['#text']

    data = {
      "#{user} is listening to" => "#{artist} - #{name}"
    }

    reply data, false
  end
end

command 'tasteometer', 'Check the musical compatibility of two Last.fm users.' do
  argc! 2

  user1, user2 = @params

  opts = {
    :method => 'tasteometer.compare',

    :type1 => :user,
    :type2 => :user,

    :value1 => user1,
    :value2 => user2,

    :limit => 15
  }

  api_call opts do |json|
    result = json['comparison']['result']

    data = {
      'Compatibility'  => "#{result['score'].to_f * 100}%",
      'Common Artists' => (result['artists']['artist'].map {|a| a['name']}.join(', '))
    }

    reply data, false

  end
end

helpers do
  def api_call opt = {}
    api_url = 'http://ws.audioscrobbler.com/2.0/'

    api_key = get_config :apikey, nil

    if api_key.nil?
      raise "A Last.fm API key must be set in the bot's configuration for this command to work."
    end

    opt[:api_key] = api_key
    opt[:format]  = 'json'

    http_get(URI(api_url), opt) do |http|
      json = MultiJson.load http.response

      raise 'invalid JSON respon' unless json
      raise json['message'] if json['error']

      yield json
    end
  end
end

