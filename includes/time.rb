
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

  # TODO: These need to support longer durations (months and years).
  # Month length is not constant. How should we deal with it? --Kabaka

  # convert seconds into [seconds, minutes, hours, days]
  def to_duration_a
    secs = (Time.now - self.to_i).to_i.abs

    t = []

    [60, 60, 24, 7].each do |n|
      secs, q = secs.divmod(n)
      t << q
    end

    t << secs
  end

  def to_duration_s
    t = to_duration_a

    # glue the pieces together, omitting ones with zero
    # this loop also takes care of pluralization
    pieces = [[t[4], " week",   "s"],
              [t[3], " day",    "s"],
              [t[2], " hour",   "s"],
              [t[1], " minute", "s"],
              [t[0], " second", "s"]]

    pieces.map! do |piece|

      unless piece[0] == 0
        s = piece[0] == 1 ? "" : piece[2]
        piece[0].to_s << piece[1] << s
      end

    end

    pieces.compact!

    pieces[-1] = "and " << pieces[-1] unless pieces.length <= 1
 
    pieces.join("#{"," unless pieces.length == 2} ")
  end

  def to_fuzzy_duration_s
    t = to_duration_a

    # feels wrong to manually zip the data like this...
    # time is incremented if cmp > thresh
    #          time   cmp  thresh       name  plural
    pieces = [[t[4], t[3],      5,   " week", "s"],
              [t[3], t[2],     16,    " day", "s"],
              [t[2], t[1],     40,   " hour", "s"],
              [t[1], t[0],     40, " minute", "s"],
              [t[0],    0,      1, " second", "s"]]

    pieces.map! do |piece|

      piece[0] += 1 if piece[1] > piece[2]
      unless piece[0] == 0
        s = piece[0] == 1 ? "" : piece[4]
        "about " << piece[0].to_s << piece[3] << s
      end

    end

    pieces.compact!

    # length is only zero if duration is zero
    return "just now" if pieces.length == 0

    return pieces[0]
  end

end
