
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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

# TODO: Support user-specified UTC offset.

def initialize
  register_script("Get the time and date from the bot.")

  register_command("time", :cmd_time,  0,  0, "Get the current time with optional time format. Parameters: [format]")
end

def cmd_time(msg, params)
  if params.length == 0
    msg.reply(Time.now.strftime("%Y-%m-%d %H:%M:%S %Z"))
  else
    msg.reply(Time.now.strftime(params[0]))
  end
end
