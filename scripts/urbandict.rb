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

require 'multi_json'

register 'Look up words on UrbanDictionary.com.'

command 'ud', 'Fetch the definition of a word from UrbanDictionary.com. If no parameter is given, fetch a random definition.' do
  if @params.empty?
    random
  else
    lookup @params.join(' ')
  end
end


url /http:\/\/(www\.)?urbandictionary\.com\/define\.php\?term=.+/ do
  word = @uri.query.split('&').detect do |query|
    query.start_with? 'term='
  end.split('=').last

  lookup word
end

helpers do
  def random
    api_call('random') do |json|
      show_definition json['list'].first
    end
  end

  def lookup word
    api_call('define', :term => word) do |json|
      json['list'][0..get_config(:max, 1).to_i-1].each do |definition|
        show_definition definition
      end
    end
  end

  def show_definition json
    data = {
      json['word'] => clean_result(json['definition'])
    }

    reply data, false
  end

  def api_call function, query = {}
    uri = URI("http://api.urbandictionary.com/v0/#{function}")

    http_get(uri, query) do |http|
      json = MultiJson.load http.response

      unless json
        raise 'The server did not give a valid reply. Please try again.'
      end

      if json['result_type'] == 'no_results'
        raise 'No results.'
      end

      yield json
    end
  end

end
# vim: set tabstop=2 expandtab:
