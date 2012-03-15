
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


def initialize
  register_script("Remember and recall short factoids.")

  register_command("remember", :cmd_remember,  1,  0, "Remember the given factoid. Should be in the form: ___ is|= ___")
  register_command("forget",   :cmd_forget,    1,  0, "Forget this factoid.")
  register_command("factoid",  :cmd_factoid,   1,  0, "Retrieve a factoid.")
end

def cmd_remember(msg, params)
  arr = params[0].downcase.split(/\sis\s|\s=\s/, 2)

  unless arr.length == 2
    msg.reply("Factoid must be given in the form: ___ is|= ___")
    return
  end

  unless get_data(arr[0]) == nil
    msg.reply("A factoid for \02#{arr[0]}\02 already exists.")
    return
  end

  store_data(arr[0], arr[1])

  msg.reply("I will remember that factoid. To recall it, use FACTOID. To delete, use FORGET.")
end

def cmd_forget(msg, params)
  key = params[0].downcase

  if get_data(key) == nil
    msg.reply("No such factoid.")
    return
  end

  delete_data(key)
  msg.reply("Factoid forgotten.")
end

def cmd_factoid(msg, params)
  key = params[0].downcase

  factoid = get_data(key)

  if factoid == nil
    msg.reply("No such factoid.")
    return
  end

  msg.reply("#{key} is #{factoid}")
end
