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

register 'Look up product information by UPC using upcdatabase.org.'

command 'upc', 'Look up a product on upcdatabase.org.' do
  argc! 1

  lookup @params.first
end

helpers do
  def lookup query
    api_call query do |json|
      unless json['valid'] == 'true'
        raise 'No results.'
      end

      buf = {
        'Name' => html_decode(json['itemname'])
      }

      unless json['avg_price'].empty?
        buf['Average Price'] = json['avg_price']
      end

      reply buf
    end
  end

  def api_call query
    query = URI.encode query
    key = get_config :apikey, nil

    unless key
      raise 'This command requires a upcdatabase.org API key. None is set in the configuration.'
    end

    uri = URI("http://api.upcdatabase.org/json/#{key}/#{query}")

    json_get uri do |json|
      yield json
    end
  end

end
# vim: set tabstop=2 expandtab:
