
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

class Time

  # convert seconds into [seconds, minutes, hours, days]
  def to_duration_a
    secs = (Time.now - self.to_i).to_i.abs

    t = []

    [60, 60, 24].each do |n|
      secs, q = secs.divmod(n)
      t << q
    end

    t << secs
  end

  def to_duration_s
    t = to_duration_a

    # glue the pieces together, omitting ones with zero
    # this loop also takes care of pluralization
    pieces = [[t[3], " day", "s"], [t[2], " hour", "s"], [t[1], " minute", "s"], [t[0], " second", "s"]]

    pieces.map! do |piece|

      unless piece[0] == 0
        s = piece[0] == 1? "" : piece[2]
        piece[0].to_s << piece[1] << s
      end

    end

    pieces.compact!

    pieces[-1] = "and " << pieces[-1] unless pieces.length <= 1
 
    pieces.join("#{"," unless pieces.length == 2} ")
  end
end
