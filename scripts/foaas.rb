#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>
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

register 'Interface with FOAAS.'

command 'fuck', 'Retrieve data from FOAAS.' do
  argc! 1

  from_only = %w[
    this        that  everything
    everyone    pink  thanks     life
  ]

  from_and_to = %w[
    off         you   donut      linus
    shakespeare king  chainsaw   outside
  ]

  type, to = @params.first.strip.split /\s+/, 2

  type.downcase!

  if from_only.include? type
    foaas type, @msg.nick
    next
  end

  unless from_and_to.include? type
    foaas type, @msg.nick
    next
  end

  unless to
    raise 'for that action, please include a recipient'
  end

  foaas type, @msg.nick, to
end


helpers do
  def foaas type, from, to = nil
    api_call type, from, to do |json|
      reply "#{json['message']} #{json['subtitle']}"
    end
  end

  def api_call type, from, to
    from = CGI.escape from
    type = CGI.escape type

    if to
      to = CGI.escape to

      uri = URI("https://foaas.herokuapp.com/#{type}/#{to}/#{from}")
    else
      uri = URI("https://foaas.herokuapp.com/#{type}/#{from}")
    end

    opts = {
      :head => {
        'Accept' => 'application/json'
      }
    }

    json_get uri, {}, false, opts  do |json|
      if json['result_type'] == 'no_results'
        raise 'No results.'
      end

      yield json
    end
  end

end
# vim: set tabstop=2 expandtab:
