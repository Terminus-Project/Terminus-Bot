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

register 'Look up amateur radio callsigns on calllook.info.'

command 'callsign', 'Look up an amateur radio callsign using calllook.info.' do
  argc! 1
  
  lookup @params.first
end

helpers do
  def lookup callsign
    api_call callsign do |json|
      unless json['status'] == 'VALID'
        raise 'Not a valid callsign.'
      end

      buf = {
        'Name'      => json['name'],
        'Latitude'  => json['location']['latitude'],
        'Longitude' => json['location']['longitude']
      }

      reply buf
    end
  end

  def api_call callsign
    callsign = URI.encode callsign

    uri = URI("http://callook.info/#{callsign}/json")

    json_get uri do |json|
      yield json
    end
  end

end
# vim: set tabstop=2 expandtab:
