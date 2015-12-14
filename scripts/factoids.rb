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

register 'Remember and recall short factoids.'

command 'remember', 'Remember the given factoid. Should be in the form: ___ is|= ___' do
  argc! 1
  arr = @params.first.split(/\sis\s|\s=\s/, 2)
  arr[0].downcase!

  unless arr.length == 2
    raise "Factoid must be given in the form: ___ is|= ___"
  end

  unless get_data(arr[0]) == nil
    raise "A factoid for \02#{arr[0]}\02 already exists."
  end

  store_data arr[0], arr[1]

  reply "I will remember that factoid. To recall it, use FACTOID. To delete, use FORGET."
end

command 'forget', 'Forget this factoid.' do
  argc! 1

  key = @params.first.downcase.rstrip

  if get_data(key) == nil
    raise "No such factoid."
  end

  delete_data key
  reply "Factoid forgotten."
end

command 'factoid', 'Retrieve a factoid.' do
  argc! 1

  key = @params.first.downcase.rstrip

  factoid = get_data key

  if factoid == nil
    raise "No such factoid."
  end

  reply "#{key} is #{factoid}"
end

# vim: set tabstop=2 expandtab:
