#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2013 Kyle Johnson <kyle@vacantminded.com>
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


class Numeric

  # Return a human-readable string which represents this number as a byte size.
  # IEC binary size prefixes are used (1024 multiples).
  #
  # @param decimals [Integer] number of decimal places to include in output
  #
  # @return [String] human-readable string
  def format_bytesize decimals = 2
    i = self

    units = %w[
      Bytes
      KiB MiB GiB
      TiB PiB EiB
      ZiB
    ]

    until i / 1024 < 1 or units.size == 1
      i /= 1024.0
      units.shift
    end

    "%.#{decimals}f %s" % [i, units.shift]
  end

  # Return a human-readable string with this number formatted to include
  # thousands separators.
  #
  # **Note: this presently makes no effort to use localization of any kind.**
  # 
  # @return [String] number with thousands separators added
  #def format_thousands_seperator
    # XXX
  #end

end
# vim: set tabstop=2 expandtab:
