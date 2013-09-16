# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Jade Rain, Shockk <shokku.ra@gmail.com>
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

register 'Converts a number from one base to another base.'

command 'hex', 'Converts a number from decimal to hex or vice versa if prefixed with 0x or suffixed with h. Parameters: [number]' do
  argc! 1

  number = @params.first

  if(number.start_with?("0x") or number.end_with?("h"))
    number.slice! "0x"
    number.slice! "h"
    reply number.to_i(16).to_s(10)
  else
    reply "0x" + number.to_i(10).to_s(16).upcase()
  end
end

command 'base', 'Converts a base to another base. Parameters: [number] [base of number] [new base]' do
  argc! 3

  number = @params[0]
  old_base = @params[1]
  new_base = @params[2]

  reply number.to_i(old_base.to_i).to_s(new_base.to_i)
end
