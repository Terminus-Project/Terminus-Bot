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

raise "reddit script requires the url_handler module" unless defined? MODULE_LOADED_URL_HANDLER

register 'Fetch information about posts and users on Reddit.'

url /\/\/(www\.)?redd(it|id\.com)/ do
  $log.info('reddit.url') { @uri.inspect }

  match = @uri.path.match(/\/(?<type>[^\/]+)\/(?<target>[^?\/]+)(\/comments\/(?<post_id>[^\/]+\/.+))?/)

  case match[:type]
  when 'u', 'user'
    get_user match[:target]

  when 'r'

    # TODO: get comments
    if match[:post_id]
      get_post match[:post_id]
    else
      get_subreddit match[:target]
    end

  else
    get_post @uri.path

  end
end

helpers do
  def get_user username
    api = URI("http://www.reddit.com/user/#{URI.escape username}/about.json")

    http_get(api, {}, true) do |http|
      data = MultiJson.load(http.response)['data']

      reply "\02#{data['name']}\02 - \02#{data['link_karma']}\02 Link Karma - \02#{data['comment_karma']}\02 Comment Karma - Joined #{Time.at(data['created_utc']).to_s}", false
    end
  end

  def get_post id
    api = URI("http://www.reddit.com/comments/#{URI.escape id}.json")

    http_get(api, {}, true) do |http|
      data = MultiJson.load(http.response, :max_nesting => 100).first['data']['children'].first['data']

      reply "#{"[NSFW] " if data["over18"]}/r/#{data["subreddit"]}: \02#{data["title"]}\02 - \02#{data["score"]}\02 Karma - \02#{data["num_comments"]}\02 Comments", false
    end
  end

  def get_subreddit name
    api = URI("http://www.reddit.com/r/#{URI.escape name}/about.json")

    http_get(api, {}, true) do |http|
      data = MultiJson.load(http.response)['data']

      reply "#{"[NSFW] " if data["over18"]}#{data["url"]}: \02#{data["title"]}\02 - \02#{data["subscribers"]}\02 subscribers - #{data["public_description"]}", false
    end
  end
end
