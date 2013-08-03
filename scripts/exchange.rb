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

register 'Look up product information by UPC using upcdatabase.org.'

command 'exchange', 'Get exchange rates from openexchangerates.org.' do
  argc! 2, 'base target'
  
  lookup *@params
end

helpers do
  def lookup base, target
    query = {
      'base' => base.upcase
    }

    api_call query do |json|
      target.upcase!

      unless json['rates'][target]
        raise 'Unknown target currency.'
      end

      time = Time.at(json['timestamp']).to_s

      reply "Exchange rate as of #{time}" => json['rates'][target]
    end
  end

  def api_call query
    key = get_config :apikey, nil

    unless key
      raise 'This command requires an openexchangerates.org API key. None is set in the configuration.'
    end

    uri = URI('http://openexchangerates.org/api/latest.json')

    query['app_id'] = key

    http_get uri, query do |http|
      begin
        json = MultiJson.load http.response
      rescue Exception => e
        raise 'The server did not give a valid reply. Please try again.'
      end

      unless json
        raise 'The server did not give a valid reply. Please try again.'
      end

      if json['error']
        raise json['description']
      end

      yield json
    end
  end

end
# vim: set tabstop=2 expandtab:
