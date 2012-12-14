#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'RPN calculator script.'

command 'rpn', 'Perform calculations using a Reverse Polish notation (postfix) calculator. Operations: add + sub - mul * exp ** div / f p' do
  argc! 1

  max_prints = get_config(:max_prints, 3).to_i
  stack, printed = [], false

  @params.first.split.each do |s|
    printed = false

    case s
    when 'add'
      s = "+"
    when 'sub'
      s = '-'
    when 'mod'
      s = '%'
    when 'mul'
      s = '*'
    when 'exp'
      s = '**'
    when 'div'
      s = '/'

    when 'f'
      reply stack.join(', ')
      max_prints -= 1 and max_prints.zero? and return
      printed = true
      next
    when 'p'
      reply stack.last.to_s
      max_prints -= 1 and max_prints.zero? and return
      printed = true
      next
    end

    stack << begin
      if s =~ /^[-+*\/%]+$/
        x, y = stack.pop 2

        x.send s, y
      else
        Float(s)
      end
    rescue
      reply "Syntax error at '#{s}'"
      next
    end
  end

  reply stack.last.to_s unless printed
end

