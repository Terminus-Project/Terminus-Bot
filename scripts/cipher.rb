
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
  register_script("Encode and decode strings using various basic ciphers")

  register_command("ciphers", :cmd_ciphers, 0,  0, "List ciphers")
  register_command("encode",  :cmd_encode,  3,  0, "Encode something using a particular cipher and key. Parameters: cipher key message")
  register_command("decode",  :cmd_decode,  3,  0, "Decode something using a particular cipher and key. Parameters: cipher key message")

  # TODO: When aliases are added to core, kill this.
  register_command("rot13",   :cmd_rot13,   0,  0, "Alias for encode/decode rot 13.")

  # the kinds of cipher
  cipher = Struct.new(:encoder, :decoder)

  @ciphers = {
    "ROT" => cipher.new(:rot_encode, :rot_decode),
    "XOR" => cipher.new(:xor_encode, :xor_decode),
  }
end


# ROT cipher
def rot_gen_tr(key)
  key = key.to_i % 26

  from = ('A'..'Z').to_a
  
  to    = from.rotate(key).join
  from  = from.join

  from  = "#{from}#{from.downcase}"
  to    = "#{to}#{to.downcase}"

  [from, to]
end

def rot_encode(key, data)
  trpair = rot_gen_tr key
  
  data.tr(trpair[0], trpair[1])
end

def rot_decode(key, data)
  trpair = rot_gen_tr key

  data.tr(trpair[1], trpair[0])
end


# XOR cipher
def xor_core(key, data)
  data.each_char.map.each_with_index { |c, i|
    (c.ord ^ key[i % key.length].ord).chr
  }.join
end

def xor_encode(key, data)
  Base64.encode64(xor_core(key, data)).gsub(/[\r\n]*/, '')
end

def xor_decode(key, data)
  xor_core(key, Base64.decode64(data))
end


# Generic Cipher API
# TODO: find a way to indicate error messages better
def do_encode(cipher, key, data)
  return "Unknown cipher #{cipher}" unless @ciphers.has_key? cipher

  encoded = self.send(@ciphers[cipher].encoder, key, data)
  encoded ? encoded : "Unable to encode"
end

def do_decode(cipher, key, data)
  return "Unknown cipher #{cipher}" unless @ciphers.has_key? cipher

  decoded = self.send(@ciphers[cipher].decoder, key, data)
  decoded ? decoded : "Unable to decode"
end

# Basic interface
def cmd_ciphers(msg, params)
  msg.reply("Available ciphers: #{@ciphers.keys.join(', ')}")
end

def cmd_encode(msg, params)
  msg.reply(do_encode(params[0].upcase, params[1], params[2]))
end

def cmd_decode(msg, params)
  msg.reply(do_decode(params[0].upcase, params[1], params[2]).gsub(/[\n\r\0]/, ''))
end


# Some nifty aliases
def cmd_rot13(msg, params)
  msg.reply(params[0].tr "A-Za-z", "N-ZA-Mn-za-m")
end
