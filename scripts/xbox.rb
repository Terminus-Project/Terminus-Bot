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

require 'json'

raise "xbox script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Retrieve information about Xbox Live players.'

command 'xbox', 'Retrieve the status of an Xbox Live player.' do
  argc! 1

  uri = URI('http://www.xboxleaders.com/api/profile.json')

  query = {
    :gamertag => @params.join(' ')
  }
  
  http_get(uri, query) do |http|

    json = JSON.parse(http.response)

    unless json.has_key? 'Data'
      raise 'Player not found.'
    end

    json = json['Data']

    data = {
      json['Gamertag'] => {
        'Status' => json['OnlineStatus'],
        'Gamer Score' => json['GamerScore'],
        'Tier' => json['Tier']
      }
    }

    reply data

  end
end

