#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Encode and decode strings using various basic ciphers'

# the kinds of cipher
cipher = Struct.new :encoder, :decoder

@@ciphers = {
  'ROT' => cipher.new(:rot_encode, :rot_decode),
  'XOR' => cipher.new(:xor_encode, :xor_decode),
  'VIG' => cipher.new(:vig_encode, :vig_decode),
}


helpers do

  # Vigenere Cipher
  def vigenere key, text, direction
    text = text.upcase.delete '^A-Z'

    key_it = key.upcase.delete('^A-Z').chars.cycle

    base = 'A'.ord
    size = 'Z'.ord - base + 1

    text.each_char.map { |c|
      offset = key_it.next.ord - base
      ((c.ord - base).send(direction, offset) % size + base).chr
    }.join
  end

  def vig_encode key, data
    vigenere key, data, :+
  end

  def vig_decode key, data
    vigenere key, data, :-
  end


  # ROT cipher
  def rot_gen_tr key
    key = key.to_i % 26

    from = ('A'..'Z').to_a

    to    = from.rotate(key).join
    from  = from.join

    to    = "#{to}#{to.downcase}"
    from  = "#{from}#{from.downcase}"

    [from, to]
  end

  def rot_encode key, data
    trpair = rot_gen_tr key

    data.tr trpair[0], trpair[1]
  end

  def rot_decode key, data
    trpair = rot_gen_tr key

    data.tr trpair[1], trpair[0]
  end


  # XOR cipher
  def xor_core key, data
    key_it = key.chars.cycle

    data.each_char.map.each { |c|
      (c.ord ^ key_it.next.ord).chr
    }.join
  end

  def xor_encode key, data
    Base64.encode64(xor_core(key, data)).delete "\r\n"
  end

  def xor_decode key, data
    xor_core key, Base64.decode64(data)
  end


  # Generic Cipher API
  # TODO: find a way to indicate error messages better
  def do_encode cipher, key, data
    return "Unknown cipher #{cipher}" unless @@ciphers.key? cipher

    encoded = self.send @@ciphers[cipher].encoder, key, data
    encoded ? encoded : "Unable to encode"
  end

  def do_decode cipher, key, data
    return "Unknown cipher #{cipher}" unless @@ciphers.key? cipher

    decoded = self.send @@ciphers[cipher].decoder, key, data
    decoded ? decoded : "Unable to decode"
  end

end

# Basic interface
command 'ciphers', 'List the available cphers.' do
  reply "Available ciphers: #{@@ciphers.keys.join(', ')}"
end

command 'encode', 'Encode some text using a particular cipher and key. Parameters: cipher key message' do
  argc! 3

  reply do_encode(@params[0].upcase, @params[1], @params[2])
end

command 'decode', 'Decode some text using a particular cipher and key. Parameters: cipher key message' do
  argc! 3

  reply do_decode(@params[0].upcase, @params[1], @params[2])
end


# TODO: When aliases are added to core, kill this. Maybe.
command 'rot13', 'Alias for encode/decode rot 13.' do
  argc! 1

  reply @params[0].tr "A-Za-z", "N-ZA-Mn-za-m"
end

# vim: set tabstop=2 expandtab:
