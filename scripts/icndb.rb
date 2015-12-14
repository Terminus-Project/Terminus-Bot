#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2015 Kyle Johnson <kyle@vacantminded.com>
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

register 'Get jokes from the Internet Chuck Norris Database.'

command 'norris', 'Get a joke from the Internet Chuck Norris Database.' do
  if @params_str.empty?
    joke
  else
    first, last = @params_str.split(/\s+/, 2)

    unless last
      joke first
    else
      joke first, last
    end
  end
end

helpers do
  def joke first = 'Chuck', last = 'Norris'
    query = {
      firstName: first,
      lastName:  last
    }

    api_call query do |json|
      unless json['type'] == 'success'
        raise 'No results.'
      end

      reply html_decode json['value']['joke']
    end
  end

  def api_call query
    uri = URI('http://api.icndb.com/jokes/random')

    json_get uri, query do |json|
      yield json
    end
  end

end
# vim: set tabstop=2 expandtab:
