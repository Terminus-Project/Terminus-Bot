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


class Time

  # TODO: These need to support longer durations (months and years).
  # Month length is not constant. How should we deal with it? --Kabaka


  # Get an Array which contains a representation of the time between now and
  # this Time. The Array is in the format `[seconds, minutes, hours, days]`.
  #
  # @return [Array] array representing the time difference
  def to_duration_a
    secs = (Time.now - self.to_i).to_i.abs

    t = []

    [60, 60, 24, 7].each do |n|
      secs, q = secs.divmod n
      t << q
    end

    t << secs
  end

  # Get a human-readable {String} describing the difference of the time between
  # now and this Time.
  #
  # @example
  #     Time.at(1367525900).to_duration_s #=> 3 days, 11 hours, 19 minutes, and
  #                                       #   6 seconds
  #
  # @return [String] human-readable description of time difference
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

    pieces.join "#{"," unless pieces.length == 2} "
  end

  # Get a human-readable {String} describing the difference of the time between
  # now and this Time.
  #
  # @example
  #     Time.at(1367525900).to_duration_s #=> about 3 days
  #
  # @return [String] human-readable description of time difference
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


  # Parse a human-readable duration and return the resulting {Time} object.
  #
  # Format is a string containing a numeric value followed by a time unit. The
  # order of durations does not matter. Repeated durations will alter the
  # {Time} value as they are parsed.
  #
  # Valid units include:
  #
  # * `s`: seconds
  # * `m`: minutes
  # * `h`: hours
  # * `d`: days
  # * `w`: weeks
  # * `y`: years
  #
  # @example
  #   Time.now                   # => 2013-05-13 10:30:00 +0000
  #   Time.parse_duration '1y5d' # => 2014-05-18 10:30:00 +0000
  #
  # @param str [String] string containing the duration representation
  def self.parse_duration str
    t = Time.now

    str.scan(/(-?[0-9]+)(\w{1})/) do
      val = $1.to_i
      case $2.downcase
      when 's'
        t = t + val
      when 'm'
        t = t + val * 60
      when 'h'
        t = t + val * 3600
      when 'd'
        t = t + val * 86400
      when 'w'
        t = t + val * 604800
      when 'y'
        a = t.to_a
        a[5] += val
        t = Time.mktime(*a)
      end
    end

    t
  end

end
# vim: set tabstop=2 expandtab:
