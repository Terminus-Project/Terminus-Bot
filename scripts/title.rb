
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
#


require "net/http"
require "uri"
require "strscan"
require "htmlentities"
require 'rexml/document'

def initialize
  register_script("Fetches titles for URLs spoken in channels.")

  register_event("PRIVMSG", :on_message)
end

def on_message(msg)
  return if msg.silent? or msg.private?

  i = 0
  max = get_config("max", 3).to_i

  URI.extract(msg.text, ["http","https"]) { |match|
    return if i >= max

    match = URI(match)

    # TODO: Find a way to make these site-specific things work after following
    # redirects so we can get info from shortened URLs.
    if match.host =~ /(www\.)?youtube\.com/ and not match.query == nil
      next if get_youtube(msg, match)
    elsif match.host =~ /(www\.)?youtu\.be/ and not match.path == nil
      next if get_youtube(msg, match)
    elsif match.host =~ /(www\.)?twitter.com/ and not match.path == nil
      next if get_twitter(msg, match)
    end
    
    get_title(msg, match)

    i += 1
  }
end

def get_youtube(msg, uri)
  $log.info('title.get_title') { "Getting YouTube info for #{uri}" }

  link, vid = "", ""

  if uri.host == 'youtu.be'
    vid = uri.path[1..uri.path.length-1].split("&")[0]
  else
    query = uri.query.split("&").select {|a| a.start_with? "v="}[0]

    return false if query == nil

    vid = query.split("=")[1]

    link = " - https://youtu.be/#{vid}"
  end

  vid = URI.escape(vid)
  api = URI("https://gdata.youtube.com/feeds/api/videos/#{vid}?v=2")

  response = get_page(api)

  return false if response == nil

  # TODO: YouTube apparently does some things with JSON. Use that if possible!
  root = REXML::Document.new(response[0].body.force_encoding('UTF-8')).root

  return false unless root.get_elements("error").empty?

  title    = root.get_elements("title").first.text.to_s
  author   = root.get_elements("author/name").first.text.to_s
  views    = root.get_elements("yt:statistics").first.attribute("viewCount").to_s

  rating   = root.get_elements("yt:rating").first

  likes, dislikes = 0, 0

  unless rating == nil
    likes    = rating.attribute("numLikes").to_s
    dislikes = rating.attribute("numDislikes").to_s
  end
  
  msg.reply("\02YouTube Video\02 #{title} \02Uploaded By:\02 #{author} \02Views:\02 #{views} \02Likes:\02 #{likes} \02Dislikes:\02 #{dislikes}#{link}", false)

  return true
end


def get_title(msg, uri)
  begin
    $log.info('title.get_title') { "Getting title for #{uri}" }

    response = get_page(uri)

    return if response == nil

    page = StringScanner.new(response[0].body.force_encoding('UTF-8'))

    page.skip_until(/<title[^>]*>/ix)
    title = page.scan_until(/<\/title[^>]*>/ix)

    return if title == nil

    len = title.length - 9
    return if len <= 0

    title = title[0..len].strip.gsub(/[[[:cntrl:]]\s]+/, " ")
    title = HTMLEntities.new.decode(title)

    msg.reply("\02Title on #{response[1]}#{" (redirected)" if response[2]}:\02 " + title, false)
  rescue => e
    $log.error('title.get_title') { "Error getting title for #{uri}: #{e}" }
    return
  end
end

def get_twitter(msg, uri)
  $log.debug('title.get_twitter') { uri.to_s }

  # TODO: Get the latest status for a linked user.
  unless uri.fragment =~ /status\/([0-9]+)/
    return false
  end

  id = URI.escape($1)
  api = URI("https://api.twitter.com/1/statuses/show.xml?id=#{id}")

  response = get_page(api)

  return false if response == nil

  # Since we're already using REXML for YouTube, we may as well use it here too.
  # (However, see the TODO about that.)
  
  root = REXML::Document.new(response[0].body.force_encoding('UTF-8')).root

  return false unless root.get_elements("error").empty?

  text     = root.get_elements("text").first.text.to_s.gsub(/[\r\n[[:print:]]]/, '')
  author   = root.get_elements("user/screen_name").first.text.to_s
  
  msg.reply("\02<@#{author}>\02 #{text}", false)

  return true
end

def get_page(uri, limit = get_config("redirects", 10), redirected = false)
  return nil if limit == 0

  response = Net::HTTP.start(uri.host, uri.port,
    :use_ssl => uri.scheme == "https",
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

    http.request Net::HTTP::Get.new(uri.request_uri)
  end

  case response

  when Net::HTTPSuccess
    return [response, uri.hostname, redirected]

  when Net::HTTPRedirection
    location = URI(response['location'])

    $log.debug("title.get_page") { "Redirection: #{uri} -> #{location} (#{limit})" }

    return get_page(location, limit - 1, true)

  else
    return nil

  end


end
