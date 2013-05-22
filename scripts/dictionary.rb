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

require 'multi_json'

need_module! 'http'

register 'Glosbe.com look-ups.'

helpers do
  def api_call func, args
    uri = URI("http://glosbe.com/gapi/#{func}")

    http_get(uri, args) do |http|
      if http.response.empty?
        raise 'No response from glosbe.com.'
      end
      yield MultiJson.load http.response
    end
  end

  def get_definition word
    args = {
      'from'   => 'en',
      'dest'   => 'en',
      'format' => 'json',
      'phrase' => word
    }

    api_call 'translate', args do |json|
      yield json
    end
  end

  def show_word json
    if json['tuc'].empty?
      raise 'No results'
    end

    reply json['phrase'] => html_decode(json['tuc'][0]['meanings'][0]['text'])
  end

end

command 'define', 'Look up some of the possible definitions of a word.' do
  argc! 1

  get_definition @params.first do |json|
    show_word json
  end
end

