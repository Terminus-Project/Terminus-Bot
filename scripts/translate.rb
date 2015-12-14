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

register 'Glosbe.com look-ups and translations.'

command 'translate', 'Translate text using glosbe.com. Use ISO 639 codes.' do
  argc! 3, 'from to text'

  translate(*@params)
end

helpers do

  def translate from, to, text
    args = {
      'from'   => from,
      'dest'   => to,
      'format' => 'json',
      'phrase' => text
    }

    api_call 'translate', args do |json|
      show_word json
    end
  end

  def show_word json
    unless json.key? 'tuc'
      raise 'No results'
    end

    buf = []

    json['tuc'].each do |val|
      if val.key? 'meanings'
        break if buf.length == 3
        buf << "\002(#{buf.length + 1})\002 #{html_decode(val['phrase']['text'])}"
      end
    end

    if buf.empty?
      raise 'No results'
    end

    reply json['phrase'] => buf.join(', ')
  end

  def api_call func, args
    uri = URI("http://glosbe.com/gapi/#{func}")

    json_get uri, args do |json|
      yield json
    end
  end

end

