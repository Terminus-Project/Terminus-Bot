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

require "strscan"
require "htmlentities"
require 'rexml/document'
require 'json'

raise "http script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Fetches titles for URLs spoken in channels.'

event :PRIVMSG do
  next if query?

  i = 0
  max = get_config(:max, 3).to_i

  matches = []

  URI.extract(@msg.text, ["http","https"]) do |match|
    next if i >= max

    next if matches.include? match
    matches << match

    match = URI(match)

    # TODO: Find a way to make these site-specific things work after following
    # redirects so we can get info from shortened URLs.
    if match.host =~ /(www\.)?youtube\.com/ and not match.query == nil
      next if get_youtube match
    elsif match.host =~ /(www\.)?youtu\.be/ and not match.path == nil
      next if get_youtube match
    elsif match.host =~ /(www\.)?twitter\.com/ and not match.path == nil
      next if get_twitter match
    elsif match.host == 'imgur.com' or match.host =~ /(www|i\.)?imgur\.com/
      next if get_imgur match
    elsif match.host == 'redd.it' or match.host =~ /(www\.)?reddit\.com/
      next if get_reddit match
    elsif match.host == 'fav.me' or match.host =~ /(.+)\.deviantart\.com/
      next if get_deviantart match
    elsif match.host =~ /(www\.)?github\.com/
      next if get_github match
    elsif match.host =~ /(www\.)?fimfiction\.net/ and match.path.start_with? "/story/"
      next if get_fimfiction match
    elsif match.host =~ /(.+\.)?derpiboo(ru.org|.ru)/
      next if get_derpibooru match
    end
    
    get_title match

    i += 1
  end
end

helpers do

  def get_youtube uri
    $log.info('title.get_title') { "Getting YouTube info for #{uri}" }

    link, vid = "", ""

    if uri.host == 'youtu.be' or uri.host == 'www.youtu.be'
      vid = uri.path[1..uri.path.length-1].split("&")[0]
    else
      query = uri.query.split("&").select {|a| a.start_with? "v="}[0]

      return false if query == nil

      vid = query.split("=")[1]

      link = " - https://youtu.be/#{vid}" if get_config(:shorten_youtube, false)
    end

    vid = URI.escape vid
    api = URI("https://gdata.youtube.com/feeds/api/videos/#{vid}?v=2")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      # TODO: YouTube apparently does some things with JSON. Use that if possible!
      root = REXML::Document.new(response.content.force_encoding('ASCII-8BIT')).root

      next unless root.get_elements("error").empty?

      title    = root.get_elements("title").first.text.to_s
      author   = root.get_elements("author/name").first.text.to_s
      views    = root.get_elements("yt:statistics").first.attribute("viewCount").to_s

      rating   = root.get_elements("yt:rating").first

      likes, dislikes = 0, 0

      unless rating == nil
        likes    = rating.attribute("numLikes").to_s
        dislikes = rating.attribute("numDislikes").to_s
      end

      reply "\02YouTube:\02 #{title} \02By:\02 #{author} \02Views:\02 #{views} \02Likes:\02 #{likes} \02Dislikes:\02 #{dislikes}#{link}", false

    end

    true
  end

  def get_title uri
    $log.info('title.get_title') { "Getting title for #{uri}" }

    Bot.http_get(uri) do |response, uri, redirected|
      begin
        next unless response.status == 200

        page = StringScanner.new response.content.force_encoding('ASCII-8BIT')

        page.skip_until /<title[^>]*>/ix
        title = page.scan_until /<\/title[^>]*>/ix

        next if title == nil

        title = HTMLEntities.new.decode title

        len = title.length - 9
        next if len <= 0

        title = title[0..len].strip.gsub(/[[[:cntrl:]]\s]+/, " ").strip

        next if title.empty?

        reply "\02Title on #{uri.host}#{" (redirected)" if redirected}:\02 #{title}", false
      rescue => e
        $log.error('title.get_title') { "Error getting title for #{uri}: #{e} #{e.backtrace.join("\n")}" }
      end
    end
  end

  def get_twitter uri
    $log.debug('title.get_twitter') { uri.to_s }

    # TODO: Get the latest status for a linked user.

    if uri.fragment
      match = uri.fragment.match(/status(es)?\/(?<id>[0-9]+)/)
    end

    unless match
      match = uri.path.match(/status\/(?<id>[0-9]+)/)

      return false unless match
    end

    id = URI.escape match[:id]
    api = URI("https://api.twitter.com/1/statuses/show.xml?id=#{id}")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      # Since we're already using REXML for YouTube, we may as well use it here too.
      # (However, see the TODO about that.)

      root = REXML::Document.new(response.content.force_encoding('ASCII-8BIT')).root

      next unless root.get_elements("error").empty?

      text     = root.get_elements("text").first.text.to_s.gsub(/[\r\n[[:cntrl:]]]/, '')
      author   = root.get_elements("user/screen_name").first.text.to_s

      reply "\02<@#{author}>\02 #{text}", false
    end
  end

  def get_fimfiction uri
    $log.debug('title.get_fimfiction') { uri.to_s }

    arg = URI.escape uri.to_s
    api = URI("http://www.fimfiction.net/api/story.php?story=#{arg}")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)["story"]
      cats = data["categories"].select {|cat, value| value }.keys.join(', ')

      reply "\02#{data["title"]}\02 by \02#{data["author"]["name"]}\02 - #{data["short_description"]} - #{cats} (Status: #{data["status"]})", false
    end
  end

  def get_derpibooru uri
    $log.debug('title.get_derpibooru') { uri.to_s }

    match = uri.path.match(/^\/(?<id>[0-9]+)$/)

    return false unless match

    host_match = uri.host.match(/^(?<server>.+)\.derpiboo/)

    api = URI("http://#{"#{host_match[:server]}." if host_match}derpiboo.ru/#{match[:id]}.json")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)

      reply "Derpibooru: #{data["tags"]} - Uploaded by \02#{data["uploader"]}\02 - #{data["width"]}x#{data["height"]} #{data["original_format"]}", false
    end
  end

  def get_github uri
    $log.debug('title.get_github') { uri.to_s }

    match = uri.path.match(/^\/(?<owner>[^\/]+)\/(?<project>[^\/]+)(\/(?<action>[^\/]+)\/(?<hash>[^\/]+))?/)

    return false unless match

    if match[:action]

      case match[:action]
      when 'commit'
        get_github_commit match

        return true
      end

    else
      # XXX - this is going to be wrong sometimes, but I am getting too
      #       tired to really care
      get_github_repo match

      return true
    end

    false
  end

  def get_deviantart uri
    $log.debug('title.get_deviantart') { uri.to_s }

    unless uri.host == 'fav.me' or uri.path =~ /^\/art\/.+/
      return false
    end

    arg = URI.escape uri.to_s
    api = URI("https://backend.deviantart.com/oembed?url=#{arg}")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)

      reply "#{data["provider_name"]}: \02#{data["title"]}\02 by \02#{data["author_name"]}\02 - #{data["category"]} - #{data["width"]}x#{data["height"]} #{data["type"]}", false
    end
  end

  def get_reddit uri
    $log.debug('title.get_reddit') { uri.to_s }

    if uri.host.end_with? 'reddit.com'
      # might not be a post

      match = uri.path.match(/\/(?<type>[^\/]+)\/(?<target>[^?\/]+)(\/comments\/(?<post_id>[^\/]+\/.+))?/)

      case match[:type]
      when 'u', 'user'
        get_reddit_user match[:target]

        return true

      when 'r'

        if match[:post_id]
          get_reddit_post match[:post_id]
        else
          get_reddit_subreddit match[:target]
        end

        return true

      end
    else
      get_reddit_post uri.path

      return true
    end

    false
  end

  def get_imgur uri
    $log.debug('title.get_imgur') { uri.to_s }

    match = uri.path.match(/\/(?<album>a\/)?(?<hash>[^\.]+)(?<extension>\.[a-z]{3})?/)

    return false unless match

    arg = URI.escape match[:hash]
    type = match[:album] ? 'album' : 'image'
    api = URI("https://api.imgur.com/2/#{type}/#{arg}.json")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)

      case type
      when 'image'
        data = data['image']['image']
      
        title = data['title'] ? data['title'] : 'No Title'

        reply "imgur: \02#{title}\02 - #{data["width"]}x#{data["height"]} #{data["type"]}#{" (animated)" if data["animated"]}", false
      when 'album'
        data = data['album']

        title = data['title'] ? data['title'] : 'No Title'

        reply "imgur album: \02#{title}\02 - #{data["images"].length} images", false
      end

      $log.debug('title.get_imgur') { data.inspect }

    end
  end

  # get_reddit helpers

  def get_reddit_user username
    api = URI("http://www.reddit.com/user/#{URI.escape username}/about.json")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)["data"]

      reply "\02#{data["name"]}\02 - \02#{data["link_karma"]}\02 Link Karma - \02#{data["comment_karma"]}\02 Comment Karma - Joined #{Time.at(data["created_utc"]).to_s}", false
    end
  end

  def get_reddit_subreddit name
    api = URI("http://www.reddit.com/r/#{URI.escape name}/about.json")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)["data"]

      reply "#{"[NSFW] " if data["over18"]}#{data["url"]}: \02#{data["title"]}\02 - \02#{data["subscribers"]}\02 subscribers - #{data["public_description"]}", false
    end
  end

  def get_reddit_post id
    api = URI("http://www.reddit.com/comments/#{URI.escape id}.json")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content, :max_nesting => 100).first["data"]["children"].first["data"]

      reply "#{"[NSFW] " if data["over18"]}/r/#{data["subreddit"]}: \02#{data["title"]}\02 - \02#{data["score"]}\02 Karma - \02#{data["num_comments"]}\02 Comments", false
    end
  end


  # get_github helpers

  def get_github_commit match
    api = URI("https://api.github.com/repos/#{match[:owner]}/#{match[:project]}/git/commits/#{match[:hash]}")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)

      reply "\02#{match[:project]}\02: #{data["message"].lines.first} - by #{data["author"]["name"]} at #{Time.parse(data["author"]["date"]).to_s}", false
    end
  end

  def get_github_repo match
    api = URI("https://api.github.com/repos/#{match[:owner]}/#{match[:project]}")

    Bot.http_get(api) do |response|
      next unless response.status == 200

      data = JSON.parse(response.content)

      reply "\02#{match[:project]}\02 (#{data["language"]}): #{data["description"]} - by #{data["owner"]["login"]}", false
    end
  end

end
