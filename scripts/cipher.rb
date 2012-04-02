def initialize
  register_script("Encode and decode strings using various basic ciphers")

  register_command("encode", :cmd_encode, 3, 0, "Encode something using a particular cipher and key")
  register_command("decode", :cmd_decode, 3, 0, "Decode something using a particular cipher and key")

  register_command("rot13", :cmd_rot13, 0, 0, "Alias for ;{en,de}code rot 13")

  # the kinds of cipher
  cipher = Struct.new(:encoder, :decoder)
  @ciphers = {
    "ROT" => cipher.new(:rot_encode, :rot_decode),
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


# Basic interface
def cmd_encode(msg, params)
  cipher = params[0].upcase
  key = params[1]
  data = params[2]

  unless @ciphers.has_key? cipher
    msg.reply("Unknown cipher #{params[0]}")
    return
  end

  encoded = self.send(@ciphers[cipher].encoder, key, data)

  unless encoded
    msg.reply("Unable to encode")
    return
  end

  msg.reply(encoded)
end

def cmd_decode(msg, params)
  cipher = params[0].upcase
  key = params[1]
  data = params[2]

  unless @ciphers.has_key? cipher
    msg.reply("Unknown cipher #{params[0]}")
    return
  end

  decoded = self.send(@ciphers[cipher].decoder, key, data)

  unless decoded
    msg.reply("Unable to decode")
    return
  end

  msg.reply(decoded)
end


# Some nifty aliases
def cmd_rot13(msg, params)
  cmd_decode(msg, ["rot", "13", params[0]])
end
