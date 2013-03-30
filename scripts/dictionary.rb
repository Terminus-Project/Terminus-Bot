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

require 'json'

raise "dictionary script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'CleanDictionary.com look-ups.'

helpers do
  def api_call func, args
    uri = URI("http://cleandictionary.com/#{func}/#{args}")

    http_get(uri) do |http|
      yield JSON.parse http.response
    end
  end

  def show_word json, type
    case type
    when :defs
      data = {
        "#{json['word']} (#{json['ps']})" => strip_def(json['defs'].first)
      }
    when :syn
      if json['synonyms'].empty?
        reply "No synonyms found for #{json['word']} (#{json['ps']})"
        return
      end

      str = strip_def(json['synonyms'][0..10].join(', ')).gsub /;/, '; '

      data = {
        "#{json['word']} (#{json['ps']})" => str
      }
    when :ant
      if json['antonyms'].empty?
        reply "No antonyms found for #{json['word']} (#{json['ps']})"
        return
      end

      str = strip_def(json['antonyms'][0..10].join(', ')).gsub /;/, '; '

      data = {
        "#{json['word']} (#{json['ps']})" => str
      }
    end

    reply data
  end

  def strip_def str
    str.gsub(/[\[\]]|\{\{[^\}]+\}\}/, '').strip.squeeze ' '
  end

  def slang json
    found = 0
    max = get_config :max, 1

    slang = json['result'].each do |result|
      result['defs'].each do |definition|
        if definition.start_with? '{{slang}}'
          found += 1

          data = {
            "#{result['word']} (#{result['ps']})" => strip_def(definition)
          }

          reply data

          return if found == max
        end
      end
    end
  end

  def search word, type = :defs
    api_call('s', word) do |json|

      if type == :slang
        slang json
      else
        json['result'][0..get_config(:max, 1).to_i-1].each do |word|
          show_word word, type
        end
      end

    end
  end
end

command 'define', 'Look up some of the possible definitions of a word.' do
  argc! 1

  search @params.first
end

command 'slang', 'Look up slang definitions of a word.' do
  argc! 1

  search @params.first, :slang
end

command 'synonyms', 'Look up synonmys of a word.' do
  argc! 1

  search @params.first, :syn
end

command 'antonyms', 'Look up antonmys of a word.' do
  argc! 1

  search @params.first, :ant
end

