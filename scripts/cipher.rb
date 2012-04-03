def initialize
  register_script("Encode and decode strings using various basic ciphers")

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
    encoded << (data[i].ord ^ key[n % key.length].ord).chr
  end

  encoded.join
end

def xor_encode(key, data)
  Base64.encode64(xor_core(key, data))
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

  encoded = self.send(@ciphers[cipher].decoder, key, data)

  return "Unable to encode" unless encoded

  return encoded
end

# Basic interface
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

  msg.reply(do_decode(cipher, key, data))
end


# Some nifty aliases
def cmd_rot13(msg, params)
  # Should this be replaced with params[0].tr 'A-Za-z', 'N-ZA-Mn-za-m'?
  msg.reply(do_encode("ROT", "13", params[0]))
end
