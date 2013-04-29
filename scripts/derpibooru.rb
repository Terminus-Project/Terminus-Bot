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

# XXX - There are going to be API breaks in an upcoming BoR update.

require 'multi_json'

need_module! 'http'

register 'Interact with Derpibooru'

command 'derpi', 'Interact with Derpibooru. Where multiple tags are allowed, separate with commas. Parameters: SEARCH tags|RANDOM tags|IMAGE id' do
  argc! 2

  case @params.shift.downcase.to_sym
  when :search
    search @params.shift
  when :random
    search @params.shift, true
  when :image
    image @params.shift
  #when :tag
  #  tag @params.shift
  else
    raise 'unknown action'
  end
end

url /(.+\.)?derpiboo(ru.org|.ru)\/(images\/)?[0-9]+/ do
  $log.info('derpibooru.url') { @uri.inspect }

  match = @uri.path.match(/\/(?<id>[0-9]+)$/)

  next unless match

  host_match = @uri.host.match(/^(?<server>.+)\.derpiboo/)

  api = URI("http://#{"#{host_match[:server]}." if host_match}derpiboo.ru/#{match[:id]}.json")

  http_get(api, {}, true) do |http|
    response = MultiJson.load http.response

    reply_with_image response, false
  end
end

url /\/\/derpicdn\.net\/media\/[^\/]+\/[0-9]+_/ do
  $log.info('derpibooru.url') { @uri.inspect }

  match = @uri.path.match(/\/(?<id>[0-9]+)__/)

  next unless match

  api = URI("https://derpiboo.ru/#{match[:id]}.json")

  http_get(api, {}, true) do |http|
    response = MultiJson.load http.response

    reply_with_image response, false
  end
end

helpers do

  def image id
    id = id.to_i

    raise 'id must be a number larger than 0' if id <= 0

    $log.info('derpibooru.search') { "Fetching Derpibooru image info for #{id}" }

    uri = URI("https://derpiboo.ru/#{id}.json")

    http_get(uri) do |http|

      response = MultiJson.load http.response

      if response.empty?
        reply "No results."
        next
      end

      reply_with_image response
    end
  end

  def search tags, random = false
    tags = tags.gsub(/,\s+/, ',').gsub(/\s+/, ' ')

    $log.info('derpibooru.search') { "Searching Derpibooru for #{tags}" }

    uri = URI('https://derpiboo.ru/search.json')
    opts = {
      :q => tags
    }

    key = get_config :key, nil
    opts[:key] = key if key

    http_get(uri, opts) do |http|

      response = MultiJson.load http.response

      if response.empty?
        reply "No results."
        next
      end

      if random
        reply_with_image response.sample
      else
        reply_with_image response.first
      end

    end
  end

  #def tag tag
  # XXX
  #end

  def reply_with_image data, include_url = true
    tags = data['tags'].split(/, /)

    rating = %w[
        safe suggestive questionable explicit
        grimdark grotesque meta text semi-grimdark
    ]

    artist, display_rating, display_tags = [], [], []

    tags.each do |tag|
      if rating.include? tag
        display_rating << tag
        next
      end

      if tag.start_with? 'artist:'
        artist << tag[7..-1]
        next
      end

      display_tags << tag
    end
    
    artist = artist.empty? ? 'not tagged' : artist.join(', ')

    tags_total = display_tags.length

    max_tags = get_config :max_tags, 10
    display_tags = display_tags[0..max_tags.to_i]

    tags_remaining = tags_total - display_tags.length

    unless tags_remaining.zero?
      display_tags = "#{display_tags.join(', ')} (and #{tags_remaining} more)"
    else
      display_tags = display_tags.join(', ')
    end

    display_rating = display_rating.join(', ')
    url = include_url ? "https://derpiboo.ru/#{data['id_number']}" : ''

    data = {
      'Derpibooru'  => url,
      'Rating'      => display_rating,
      'Artist'      => artist,
      'Tags'        => display_tags,
      'Uploader'    => data['uploader'],
      'Score'       => "#{data['score']} (#{data['upvotes']} Up / #{data['downvotes']} Down)",
      "#{data['width']}x#{data['height']}" => data['original_format']
    }

    reply data, false
  end

end
