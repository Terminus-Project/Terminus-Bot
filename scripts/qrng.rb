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

register 'Retrieve random numbers from ANU\'s quantum random number generator.'

command 'qrng', 'Get truly random numbers from a quantum random number generator. Syntax: [uint8|uint16|hex16 [count]]' do
  
  type, count = @params_str.split

  if type
    type.downcase!

    unless %w[uint8 uint16 hex16].include? type
      raise 'unknown type (valid: uint8, uint16, hex16)'
    end
  else
    type = 'uint16'
  end

  if count
    count = count.to_i

    if count < 1 or count > 100
      raise 'count must be between 1 and 100'
    end
  else
    count = 1
  end

  qrng type, count
end

helpers do
  def qrng type, count
    query = {
      'length' => count,
      'type'   => type
    }

    if type == 'hex16'
      query['size'] = 1
    end

    api_call query do |json|
      if json['data'].empty?
        raise 'No numbers returned.'
      end

      reply json['data'].join ' '
    end
  end

  def api_call query
    uri = URI('https://qrng.anu.edu.au/API/jsonI.php')

    json_get uri, query do |json|
      yield json
    end
  end

end

# vim: set tabstop=2 expandtab:
