
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

  register_command("ciphers", :cmd_ciphers, 0, 0, "List ciphers")
  register_command("encode", :cmd_encode, 3, 0, "Encode something using a particular cipher and key")
  register_command("decode", :cmd_decode, 3, 0, "Decode something using a particular cipher and key")

  register_command("rot13", :cmd_rot13, 0, 0, "Alias for ;{en,de}code rot 13")

  # the kinds of cipher
  cipher = Struct.new(:encoder, :decoder)
  @ciphers = {
    "ROT" => cipher.new(:rot_encode, :rot_decode),
    "XOR" => cipher.new(:xor_encode, :xor_decode),
  }
end


# ROT cipher
def rot_gen_tr(key)
  key = key.to_i

  # 0 < key < 26, anything else makes no sense or is redundant
  return nil unless 0 < key and key < 26

  alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  from = alpha + alpha.downcase

  # rotate
  (0...key).each { |i| alpha = alpha[1..-1] + alpha[0] }

  to = alpha + alpha.downcase

  return [from, to]
end

def rot_encode(key, data)
  trpair = rot_gen_tr key

  return nil if trpair == nil

  return data.tr(trpair[0], trpair[1])
end

def rot_decode(key, data)
  trpair = rot_gen_tr key

  return nil if trpair == nil

  return data.tr(trpair[1], trpair[0])
end


# XOR cipher
def xor_core(key, data)
  n = data.length

  encoded = []
  (0...n).each do |i|
    encoded << (data[i].ord ^ key[i % key.length].ord).chr
  end

  encoded.join
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

  return "Unable to encode" unless encoded

  return encoded
end

def do_decode(cipher, key, data)
  return "Unknown cipher #{cipher}" unless @ciphers.has_key? cipher

  decoded = self.send(@ciphers[cipher].decoder, key, data)

  return "Unable to decode" unless decoded

  return decoded
end

# Basic interface
def cmd_ciphers(msg, params)
  msg.reply("Available ciphers: #{@ciphers.keys.join(', ')}")
end

def cmd_encode(msg, params)
  cipher = params[0].upcase
  key = params[1]
  data = params[2]

  msg.reply(do_encode(cipher, key, data))
end

def cmd_decode(msg, params)
  cipher = params[0].upcase
  key = params[1]
  data = params[2]

  msg.reply(do_decode(cipher, key, data).gsub(/[\n\r\0]/, '.'))
end


# Some nifty aliases
def cmd_rot13(msg, params)
  msg.reply(params[0].tr "A-Za-z", "N-ZA-Mn-za-m")
end
