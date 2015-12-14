#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Interact with F-list.net'

command 'f-list', 'Interact with F-list. Parameters: CHARACTER name | COMPARE name1 name2' do
  argc! 2

  case @params.shift.downcase.to_sym
  when :character
    character @params.shift
  when :compare
    argc! 3 and @params.shift

    compare @params.shift, @params.shift
  else
    raise 'unknown action'
  end
end

url(/^https?:\/\/(www\.)?f-list\.net\/c\/.+/) do
  $log.info('flist.url') { @uri.inspect }

  match = @uri.path.match(/^\/c\/(?<name>[^\/]+)\/?/)

  next unless match

  character match[:name], false
end

helpers do

  def character name, prefix = true
    $log.debug('flist.character') { name.inspect }
    uri = URI('http://www.f-list.net/json/api/character-get.php')

    opts = {
      'name' => name
    }

    json_get uri, opts do |response|
      if response.empty?
        raise 'No results.'
      end

      if response['error'] and not response['error'].empty?
        raise response['error']
      end

      response = response['character']

      data = {
        'Name'        => response['name'],
        'Description' => html_decode(response['description']),
        'Views'       => response['pageviews'],
        'Created'     => response['datetime_created'],
        'Updated'     => response['datetime_changed']
      }

      reply data, prefix
    end
  end

  def compare name1, name2
    uri = URI('http://www.f-list.net/json/api/character-kinks.php')

    opts = {
      'name' => name1
    }

    json_get uri, opts do |response|
      if response.empty?
        raise "(#{name1}) Unknown error performing look-up."
      end

      if response['error'] and not response['error'].empty?
        raise "#{(name1)} #{response['error']}"
      end

      kinks1, choices = {}, {}

      response['kinks']['']['items'].each do |kink|
        kinks1[kink['name']] = kink['choice']

        choices[kink['choice']] ||= {
          :total    => 0,
          :matches  => 0
        }
      end

      opts = {
        'name' => name2
      }

      json_get uri, opts do |response|
        if response.empty?
          raise "(#{name2}) Unknown error performing look-up."
        end

        if response['error'] and not response['error'].empty?
          raise "#{(name2)} #{response['error']}"
        end

        response['kinks']['']['items'].each do |kink|
          choices[kink['choice']] ||= {
            :total    => 0,
            :matches  => 0
          }

          choices[kink['choice']][:total] += 1

          if kinks1[kink['name']] == kink['choice']
            choices[kink['choice']][:matches] += 1
          end
        end

        data, overall_matches, overall_total = {}, 0, 0

        choices.each do |choice, stats|
          data[choice] = "#{stats[:matches]}/#{stats[:total]} (#{(stats[:matches].to_f/stats[:total].to_f * 100).to_i}% Match)"
          overall_matches += stats[:matches]
          overall_total   += stats[:total]
        end

        data['overall'] = "#{overall_matches}/#{overall_total} (#{(overall_matches.to_f/overall_total.to_f * 100).to_i}% Match)"

        reply data
      end
    end
  end
end
# vim: set tabstop=2 expandtab:
