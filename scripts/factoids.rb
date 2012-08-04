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

def initialize
  register_script "Remember and recall short factoids."

  register_command "remember", :cmd_remember,  1,  0, nil, "Remember the given factoid. Should be in the form: ___ is|= ___"
  register_command "forget",   :cmd_forget,    1,  0, nil, "Forget this factoid."
  register_command "factoid",  :cmd_factoid,   1,  0, nil, "Retrieve a factoid."
end

def cmd_remember msg, params
  arr = params[0].downcase.split /\sis\s|\s=\s/, 2

  unless arr.length == 2
    msg.reply "Factoid must be given in the form: ___ is|= ___"
    return
  end

  unless get_data(arr[0]) == nil
    msg.reply "A factoid for \02#{arr[0]}\02 already exists."
    return
  end

  store_data arr[0], arr[1]

  msg.reply "I will remember that factoid. To recall it, use FACTOID. To delete, use FORGET."
end

def cmd_forget msg, params
  key = params[0].downcase

  if get_data(key) == nil
    msg.reply "No such factoid."
    return
  end

  delete_data key
  msg.reply "Factoid forgotten."
end

def cmd_factoid msg, params
  key = params[0].downcase

  factoid = get_data key

  if factoid == nil
    msg.reply "No such factoid."
    return
  end

  msg.reply "#{key} is #{factoid}"
end

