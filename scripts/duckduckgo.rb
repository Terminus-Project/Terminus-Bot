#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2013 Kyle Johnson <kyle@vacantminded.com>
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

require 'multi_json'

register 'Perform searches on duckduckgo.com.'

command 'ddg', 'Search the Internet using duckduckgo.com.' do
  argc! 1

  bang 'ducky', @params.first
end

command 'define', 'Define a term with duckduckgo.com.' do
  argc! 1

  define @params.first
end

command 'ask', 'Ask duckduckgo.com to complete a complex query.' do
  argc! 1

  answer @params.first
end


helpers do
  def bang type, query
    api_call "!#{type} #{query}" do |json|
      if json['Redirect'].start_with? 'https://duckduckgo.com/?q='
        raise 'No results.'
      end

      reply json['Redirect']
    end
  end

  def answer query
    api_call query do |json|
      if json['Answer'].empty?
        raise 'No results.'
      end

      reply json['Answer']
    end
  end

  def define query
    api_call query do |json|
      buf = []

      unless json['Abstract'].empty?
        if json['AbstractSource'].empty?
          source = ''
        else
          source = " (Source: #{json['AbstractSource']})"
        end

        buf << "\002(#{buf.length + 1})\002 #{html_decode json['Abstract']}#{source}"
      end

      unless json['Definition'].empty?
        if json['DefinitionSource'].empty?
          source = ''
        else
          source = " (Source: #{json['DefinitionSource']})"
        end

        buf << "\002(#{buf.length + 1})\002 #{html_decode json['Definition']}#{source}"
      end

      unless json['RelatedTopics'].empty?
        json['RelatedTopics'].each do |related_topic|

          if related_topic['Topics']
            related_topic['Topics'].each do |topic|
              break if buf.length == 3

              buf << "\002(#{buf.length + 1})\002 #{html_decode topic['Text']}"
            end
          else
            break if buf.length == 3

            buf << "\002(#{buf.length + 1})\002 #{html_decode related_topic['Text']}"
          end
        end
      end

      if buf.empty?
        raise 'No results.'
      end

      reply_without_prefix query => buf.join(' ').tr_s(' ', ' ')
    end
  end

  def api_call query
    opts = {
      'q'           => query,
      'format'      => 'json',
      'no_redirect' => '1',
      'no_html'     => '1',
      'kp'          => '-1'
    }

    uri = URI('https://api.duckduckgo.com/')

    http_get(uri, opts) do |http|
      json = MultiJson.load http.response

      unless json
        raise 'The server did not give a valid reply. Please try again.'
      end

      yield json
    end
  end

end
# vim: set tabstop=2 expandtab:
