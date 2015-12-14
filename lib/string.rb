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


class String

  def wildcard_match s

    # TODO: This probably needs to obey CASEMAPPING since it will be used for
    # hostname matching and probably nothing else. --Kabaka

    # Since this is primarily going to be used for hostmask matches, we should
    # escape these so that character classes aren't used, as that might
    # produce unexpected results.
    #
    # If it isn't obvious, this escapes [ and ]. So many backslashes!
    s.gsub!(/([\[\]])/, '\\\\\1')

    # Wildcard matches can be done with fnmatch, a globbing function. This
    # doesn't touch the filesystem.
    File.fnmatch s, self

  end

  def fix_encoding!
    encode!(
      (Bot::Conf[:core][:encoding] || 'ASCII-8BIT'),
      :invalid => :replace,
      :undef   => :replace
    )
  end

end
# vim: set tabstop=2 expandtab:
