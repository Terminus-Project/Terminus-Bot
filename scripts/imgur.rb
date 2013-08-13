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

need_module! 'http', 'url_handler'

register 'Fetch information from Imgur.'

url /\/\/((www|i)\.)?imgur\.com\// do
  $log.info('imgur.url') { @uri.inspect }

  match = @uri.path.match(/\/((?<type>a|gallery)\/)?(?<id>[^\.\/]+)(?<extension>\.[a-z]{3})?(\/comment\/(?<comment_id>\d+)$)?/)
  
  $log.info('imgur.url') { match.inspect }

  next unless match

  if match[:comment_id]
    $log.debug('imgur.url') { "comment" }
    comment match[:comment_id]
  else

    case match[:type]
    when nil
      $log.debug('imgur.url') { "image" }
      image match[:id]
    when 'a'
      $log.debug('imgur.url') { "album" }
      album match[:id]
    when 'gallery'
      $log.debug('imgur.url') { "gallery" }
      gallery match[:id]
    end
  end
end

helpers do
  def image id
    api_call 'image', id do |data|
      title = data['title'] || 'No Title'
      reply "imgur: \02#{title}\02 - #{data['width']}x#{data['height']} #{data['type']}#{' (animated)' if data['animated']}", false
    end
  end

  def album id
    api_call 'album', id do |data|
      title = data['title'] || 'No Title'
      reply "imgur album: \02#{title}\02 - #{data['images_count']} images", false
    end
  end

  def gallery id
    api_call 'gallery', id do |data|
      title = data['title'] || 'No Title'
      if data['is_album']
        reply "imgur album: \02#{title}\02 - #{data['images_count']} images", false
      else
        reply "imgur: \02#{title}\02 - #{data['width']}x#{data['height']} #{data['type']}#{' (animated)' if data['animated']}", false
      end
    end
  end

  def comment id
    api_call 'comment', id do |data|
      reply "imgur comment: \02<#{data['author']}>\02 #{data['comment']}", false
    end
  end

  def api_call endpoint, path
    client_id = get_config :client_id, nil
    
    if client_id.nil?
      raise 'client_id must be set for imgur script to operate'
    end

    opts = {
      :head => {
        'Authorization' => "Client-ID #{client_id}"
      }
    }

    uri = URI("https://api.imgur.com/3/#{endpoint}/#{path}.json")

    json_get uri, {}, true, opts do |data|
      unless data['success']
        raise data['data']['error']
      end

      yield data['data']
    end
  end
end

# vim: set tabstop=2 expandtab:

