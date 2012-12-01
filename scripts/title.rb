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

def initialize
  raise "http script requires the http_client module" unless defined? MODULE_LOADED_HTTP

  register_script "Fetches titles for URLs spoken in channels."

  register_event :PRIVMSG, :on_message
end

def on_message msg
  return if msg.private?

  i = 0
  max = get_config(:max, 3).to_i

  matches = []

  URI.extract(msg.text, ["http","https"]) { |match|
    return if i >= max

    next if matches.include? match
    matches << match

    match = URI(match)

    # TODO: Find a way to make these site-specific things work after following
    # redirects so we can get info from shortened URLs.
    if match.host =~ /(www\.)?youtube\.com/ and not match.query == nil
      next if get_youtube(msg, match)
    elsif match.host =~ /(www\.)?youtu\.be/ and not match.path == nil
      next if get_youtube(msg, match)
    elsif match.host =~ /(www\.)?twitter.com/ and not match.path == nil
      next if get_twitter(msg, match)
    elsif match.host == 'fav.me'
      next if get_deviantart(msg, match)
    elsif match.host =~ /(www\.)?fimfiction.net/ and match.path.start_with? "/story/"
      next if get_fimfiction(msg, match)
    end
    
    get_title msg, match

    i += 1
  }
end

def get_youtube msg, uri
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

    msg.reply "\02YouTube:\02 #{title} \02By:\02 #{author} \02Views:\02 #{views} \02Likes:\02 #{likes} \02Dislikes:\02 #{dislikes}#{link}", false

  end
  
  true
end

def get_title msg, uri
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

      msg.reply "\02Title on #{uri.host}#{" (redirected)" if redirected}:\02 #{title}", false
    rescue => e
      $log.error('title.get_title') { "Error getting title for #{uri}: #{e} #{e.backtrace.join("\n")}" }
    end
  end
end

def get_twitter msg, uri
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

    msg.reply "\02<@#{author}>\02 #{text}", false
  end

  true
end

def get_fimfiction msg, uri
  $log.debug('title.get_fimfiction') { uri.to_s }

  arg = URI.escape uri.to_s
  api = URI("http://www.fimfiction.net/api/story.php?story=#{arg}")

  Bot.http_get(api) do |response|
    next unless response.status == 200

    data = JSON.parse(response.content)["story"]
    cats = data["categories"].select {|cat, value| value }.keys.join(', ')

    msg.reply "\02#{data["title"]}\02 by \02#{data["author"]["name"]}\02 - #{data["short_description"]} - #{cats} (Status: #{data["status"]})", false
  end
end

def get_deviantart msg, uri
  $log.debug('title.get_deviantart') { uri.to_s }

  arg = URI.escape uri.to_s
  api = URI("https://backend.deviantart.com/oembed?url=#{arg}")

  Bot.http_get(api) do |response|
    next unless response.status == 200

    data = JSON.parse(response.content)

    msg.reply "#{data["provider_name"]}: \02#{data["title"]}\02 by \02#{data["author_name"]}\02 - #{data["category"]} - #{data["width"]}x#{data["height"]} #{data["type"]}", false
  end
end
