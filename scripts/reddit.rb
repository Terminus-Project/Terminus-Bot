#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2014 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# Rylee Fowler <rylee@rylee.me> (http://terminus-bot.net/)
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

need_module! 'url_handler', 'regex_handler'

register 'Fetch information about posts and users on reddit.'

url(/\/\/((www|pay)\.)?redd(it|id\.com)/) do
  $log.info('reddit.url') { @uri.inspect }

  match = @uri.path.match(
    /\/(?<type>[^\/]+)\/(?<target>[^?\/]+)(\/comments\/(?<long_id>(?<post_id>[^\/]+)\/(?<post_name>[^\/]+)(\/(?<comment_id>[^\/]+))?)?)?/
  )

  $log.debug('reddit.url') { match.inspect }

  if match
    case match[:type]
    when 'u', 'user'
      get_user match[:target]

    when 'r'

      if match[:comment_id]
        get_comment match[:long_id]
      elsif match[:post_id]
        get_post match[:post_id]
      else
        get_subreddit match[:target]
      end

    else
      get_post @uri.path

    end
  else
    get_post @uri.path
  end
end

regex(/(^|\s)\/r\/(?<name>[^\/\s]+)\/?(\s|$)/) do
  get_subreddit @match[:name]
end

regex(/(^|\s)\/u\/(?<name>[^\/\s]+)\/?(\s|$)/) do
  get_user @match[:name]
end

command 'serendipity', 'Get a random reddit post.' do
  get_random
end

helpers do
  def get_user username
    api = URI("http://www.reddit.com/user/#{URI.escape username}/about.json")

    json_get api, {}, true do |json|
      data = json['data']

      reply "\02#{data['name']}\02 - \02#{data['link_karma']}\02 Link Karma - \02#{data['comment_karma']}\02 Comment Karma - Joined #{Time.at(data['created_utc']).to_s}", false
    end
  end

  def get_post id
    api = URI("http://www.reddit.com/comments/#{URI.escape id}.json")

    json_get api, {}, true do |json|
      data = json.first['data']['children'].first['data']

      reply "#{"[NSFW] " if data["over_18"]}/r/#{data["subreddit"]}: \02#{html_decode data["title"]}\02 - \02#{data["score"]}\02 Karma - \02#{data["num_comments"]}\02 Comments", false
    end
  end

  def get_random
    api = URI("http://www.reddit.com/random/.json")

    json_get api, {}, true do |json|
      data = json.first['data']['children'].first['data']

      reply "#{"[NSFW] " if data["over_18"]}http://redd.it/#{data['id']} - /r/#{data["subreddit"]}: \02#{html_decode data["title"]}\02 - \02#{data["score"]}\02 Karma - \02#{data["num_comments"]}\02 Comments", false
    end
  end

  def get_comment id
    api = URI("http://www.reddit.com/comments/#{URI.escape id}.json")

    query = { 'depth' => 1 }

    json_get api, query, true do |json|
      data = json[1]['data']['children'].first['data']

      score = data['ups'].to_i - data['downs'].to_i

      buf, attributes = [], []

      buf << '[NSFW] ' if data['over_18']
      buf << "Comment by #{data['author']}:"
      buf << "\02#{score}\02 Karma"

      attributes << 'Gilded' unless data['gilded'].zero?
      attributes << 'Edited' if data['edited']

      unless attributes.empty?
        buf << "(#{attributes.join(', ')})"
      end

      buf << '-'

      buf << data['body']

      reply_without_prefix buf.join ' '
    end
  end

  def get_subreddit name
    api = URI("http://www.reddit.com/r/#{URI.escape name}/about.json")

    json_get api, {}, true do |json|
      data = json['data']

      reply "#{"[NSFW] " if data["over_18"]}#{data["url"]}: \02#{html_decode data["title"]}\02 - \02#{data["subscribers"]}\02 subscribers - #{html_decode data["public_description"]}".slice(0, 512), false
    end
  end
end
# vim: set tabstop=2 expandtab:
