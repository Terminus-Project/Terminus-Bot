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

need_module! 'http'

register 'Interact with e621.'

command 'e621', 'Interact with e621. Parameters: SEARCH tags|RANDOM tags|IMAGE id' do
  argc! 2

  case @params.shift.downcase.to_sym
  when :search
    search @params.shift
  when :random
    search @params.shift, true
  when :image
    image @params.shift
  else
    raise 'unknown action'
  end
end

url /\/\/e621\.net\/post\/show\/[0-9]+/ do
  $log.info('e621.url') { @uri.inspect }

  match = @uri.path.match(/\/(?<id>[0-9]+)\/?/)
  image match[:id], false, true
end

url /\/\/.*\.e621\.net\/data\/.+\/[0-9a-fA-F]+\.\w{3}$/ do
  $log.info('e621.url') { @uri.inspect }

  match = @uri.path.match(/\/(?<id>[0-9a-fA-F]+)\.\w{3}$/)
  search "md5:#{match[:id]}", false, true, true
end

url /\/\/e621\.net\/comment\/show\/[0-9]+/ do
  $log.info('e621.url') { @uri.inspect }

  match = @uri.path.match(/\/(?<id>[0-9]+)\/?/)
  comment match[:id], true
end

helpers do

  def login_args
    login     = get_config :login
    password  = get_config :password_hash

    if login and password
      {'login' => login, 'password_hash' => password}
    else
      {}
    end
  end

  def image id, include_url = true, silent_err = false
    id = id.to_i

    if id <= 0
      return if silent_err
      raise 'id must be a number larger than 0'
    end

    $log.info('e621.image') { id }

    api = URI("https://e621.net/post/show/#{id}.json")

    json_get api, {}, silent_err do |json|
      raise 'No results.' if json.empty?

      reply_with_image json, include_url
    end
  end

  def comment id, silent_err = false
    id = id.to_i

    if id <= 0
      return if silent_err
      raise 'id must be a number larger than 0'
    end

    $log.info('e621.comment') { id }

    api = URI("https://e621.net/comment/show/#{id}.json")

    json_get api, login_args, silent_err do |json|
      raise 'No results.' if json.empty?

      reply_with_comment json
    end
  end


  def search tags, random = false, include_url = true, silent_err = false
    $log.info('e621.search') { tags }

    api = URI('https://e621.net/post/index.json')

    args = {
      'tags' => tags
    }

    json_get api, args, silent_err do |json|
      raise 'No results.' if json.empty?

      if random
        reply_with_image json.sample, include_url
      else
        reply_with_image json.first, include_url
      end
    end
  end



  def reply_with_image data, include_url = true
    tags = data['tags'].split

    max_tags = get_config :max_tags, 10
    display_tags = tags[0..max_tags.to_i]

    tags_remaining = tags.length - display_tags.length

    unless tags_remaining.zero?
      display_tags = "#{display_tags.join(', ')} (and #{tags_remaining} more)"
    else
      display_tags = display_tags.join(', ')
    end

    case data['rating']
    when 'e'
      display_rating = 'Explicit'
    when 'q'
      display_rating = 'Questionable'
    when 's'
      display_rating = 'Safe'
    else
      display_rating = data['rating']
    end

    url = include_url ? "https://e621.net/post/show/#{data['id']}" : ''

    reply_without_prefix  'e621'  => url,
      'Rating'   => display_rating,
      'Tags'     => display_tags,
      'Uploader' => data['author'],
      'Score'    => data['score'],
      "#{data['width']}x#{data['height']}" => data['file_ext']
  end

  def reply_with_comment data
    reply_without_prefix "\002<#{data['creator']}>\002 #{clean_result data['body']}"
  end

end
# vim: set tabstop=2 expandtab:
