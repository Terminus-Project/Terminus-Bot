
#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

require "uri"


def initialize
  registerModule("Text", "Simple text manipulation commands.")

  registerCommand("Text", "length", "Measure the length of the provided text.", "text")
  registerCommand("Text", "reverse", "Reverse text.", "text")
  registerCommand("Text", "upcase", "Convert text to all upper-case.", "text")
  registerCommand("Text", "downcase", "Convert text to all lower-case.", "text")
  registerCommand("Text", "swapcase", "Change all upper-case characters in text to lower-case, and all lower-case characters to upper-case.", "text")
  registerCommand("Text", "oct", "Treats leading characters of text as a string of octal digits (with an optional sign) and returns the corresponding number. Returns 0 if the conversion fails.", "text")
  registerCommand("Text", "hex", "Treats leading characters from str as a string of hexadecimal digits (with an optional sign and an optional 0x) and returns the corresponding number. Zero is returned on error. ", "text")
  registerCommand("Text", "oct", "Return the Integer ordinal of a one-character string.", "text")
  registerCommand("Text", "urlencode", "Escapes text as a URL parameter.", "text")
  registerCommand("Text", "urldecode", "Decodes text as an encoded URL parameter.", "text")
end

def cmd_length(message)
  reply(message, message.args.length.to_s)
end

def cmd_reverse(message)
  reply(message, message.args.reverse)
end

def cmd_upcase(message)
  reply(message, message.args.upcase)
end

def cmd_downcase(message)
  reply(message, message.args.downcase)
end

def cmd_swapcase(message)
  reply(message, message.args.swapcase)
end

def cmd_hex(message)
  reply(message, message.args.hex.to_s)
end

def cmd_oct(message)
  reply(message, message.args.oct.to_s)
end

def cmd_ord(message)
  reply(message, message.args.ord.to_s)
end

def cmd_urlencode(message)
  reply(message, URI.escape(message.args))
end

def cmd_urldecode(message)
  reply(message, URI.unescape(message.args))
end
