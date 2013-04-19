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
# SOFTARE.
#

require 'multi_json'

raise "youtube script requires the url_handler module" unless defined? MODULE_LOADED_URL_HANDLER

register 'Fetch information from YouTube.'

url /\/\/(youtu\.be\/.+|(www\.)?youtube\.com\/.+[?&]v=.+)/ do
  $log.info('youtube.url') { @uri.inspect }

  link, vid = '', ''

  if @uri.host == 'youtu.be' or @uri.host == 'www.youtu.be'
    vid = @uri.path[1..@uri.path.length-1].split("&")[0]
  else
    query = @uri.query.split('&').select {|a| a.start_with? 'v='}[0]

    next if query == nil

    vid = query.split('=')[1]

    link = " - https://youtu.be/#{vid}" if get_config(:shorten_links, false)
  end

  api = URI('https://www.googleapis.com/youtube/v3/videos')

  opts = {
    :id   => vid,
    :part => 'contentDetails,statistics,snippet',
    :key  => 'AIzaSyDyoH7a9ABi-QJ3f5qS1PsLZJbnxvzKvxc'
  }

  http_get(api, opts, true) do |http|
    json = MultiJson.load(http.response)['items'].first

    if json['error']
      raise json['error']['errors'].first['message']
    end

    duration  = json['contentDetails']['duration'].match(/^PT((?<minutes>[0-9]+)M)?(?<seconds>[0-9]+)S$/)
    duration  = duration[:minutes].to_i * 60 + duration[:seconds].to_i

    data = {
      'YouTube'  => json['snippet']['title'],
      'By'       => json['snippet']['channelTitle'],
      'Views'    => json['statistics']['viewCount'],
      'Duration' => Time.at(Time.now.to_i + duration).to_duration_s,
      'Likes'    => json['statistics']['likeCount'],
      'Dislikes' => json['statistics']['dislikeCount']
    }

    reply data, false

  end

end

