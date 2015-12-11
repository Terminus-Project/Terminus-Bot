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

register 'Retrieve information about Xbox Live players.'

command 'xbox', 'Retrieve information about Xbox Live players. Syntax: PROFILE gamertag' do
  argc! 2

  case @params.first.downcase.to_sym
  when :profile
    profile @params.last
  end
end


helpers do

  def profile gamertag
    api_call('profile', gamertag) do |json|
      data = {
        json['gamertag'] => {
          'Subscription' => json['status'].capitalize,
          'Gamer Score'  => json['gamerscore'],
          'Reputation'   => json['reputation'],
          'Cheater'      => json['cheater']
        }
      }

      reply data
    end
  end

  def api_call func, gamertag
    uri = URI("http://www.xboxleaders.com/api/#{func}.json")

    query = {
      :gamertag => gamertag
    }


    http_get(uri, query) do |http|
      json = MultiJson.load(http.response)

      unless json['exists']
        raise 'Player not found.'
      end

      yield json
    end
  end
end
# vim: set tabstop=2 expandtab:
