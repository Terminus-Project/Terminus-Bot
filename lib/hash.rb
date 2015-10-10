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


class Hash

  # Recursively format the Hash for use in an IRC message.
  #
  # This is primarily for use by {Bot::Command#reply}.
  #
  # @example
  #     data = {
  #       'Foo' => 'bar'
  #     }
  #
  #     data.to_s_irc #=> "\02Foo:\02 bar"
  #
  # @example
  #     data = {
  #       'Foo' => {
  #         'Bar' => 'baz'
  #       }
  #     }
  #
  #     data.to_s_irc #=> "\02Foo:\02 \02Bar:\02 baz"
  def to_s_irc
    each.map do |key, value|
      if value.is_a? Hash
        "\02#{key}:\02 #{value.to_s_irc}".strip
      else
        "\02#{key}:\02 #{value}".strip
      end
    end.join(' ')
  end

end
# vim: set tabstop=2 expandtab:
