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

need_module! 'ignores'

register 'Manipulate the bot\'s hostmask-based ignore list.'

command 'ignores', 'List all active ignores.' do
  level! 4

  if Ignores.empty?
    reply "There are no active ignores."
    next
  end

  reply Ignores.join(", ")
end

command 'ignore', 'Ignore the given hostmask.' do
  level! 4 and argc! 1

  mask = @params.first

  if mask =~ /\s/
    raise 'Invalid banmask (spaces are not permitted).'
  end

  mask << "!*@*" unless mask =~ /[!@*]/
 
  if Ignores.include? mask
    raise "Already ignoring #{mask}"
  end

  Ignores << mask

  reply "Ignore added: #{mask}"
end


command 'unignore', 'Remove the given ignore.' do
  level! 4 and argc! 1

  mask = @params.first

  mask << "!*@*" unless mask =~ /[!@*]/

  unless Ignores.include? mask
    raise "No such ignore."
  end

  Ignores.delete mask

  reply "Ignore removed: #{mask}"
end

# vim: set tabstop=2 expandtab:
