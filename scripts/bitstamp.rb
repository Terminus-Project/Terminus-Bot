#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2014 Rylee Elise Fowler <rylee@rylee.me>
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

need_module! 'http'

register 'interface with the bitstamp bitcoin API'

command 'btc', 'Get the current BTC -> USD exchange rate from BitStamp' do
  uri = URI('https://www.bitstamp.net/api/ticker/')

  json_get uri do |json|
    data = {
      'BTC to USD Trade Value (Bitstamp)' => {
        'Last'    => json['last'],
        'High'    => json['high'],
        'Low'     => json['low'],
        'Volume (last 24 hours)'  => json['volume'],
        'Highest buy order' => json['bid'],
        'Lowest sell order' => json['ask']
      }
    }
    reply data
  end
end
# vim: set tabstop=2 expandtab:
