#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2014 Rylee Fowler <rylee@rylee.me>
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

require 'ostruct'

# TODO:
#   - Configurable max dice.
#   - MORE TOKENS (consult the roll20 dice reference if in need of ideas)
#   - SANITY CHECKS ABOUND

# Input of the form 'd10' or 'k3' or 's20' is accepted through this regex.

# TODO: Add ability to T-b to define constants for your scripts.


register 'Provides a high-flexibility dice simulator.'

command 'dice', 'Roll dice.' do
  dice = []

  @params.each do |die_str|
    # TODO verify
    count, token_str = die_str.scan(/(\d+)(.*)/).first
    next unless count
    tokens           = token_str.scan(/(\S)(\d+)/)

    dice_spec = { count: count, tokens: tokens }

    dice << roll_dice(dice_spec)

  end

  reply = {}

  dice.each.with_index do |die, index|
    reply["Dice set #{index + 1}"] = die.to_s_irc
  end
  reply reply
end

helpers do
  def roll_dice dice_spec
    tokens = {
      'd' => :sides,
      'k' => :keep,
      '*' => :mul,
      '+' => :add
    }

    params = OpenStruct.new

    params.count = dice_spec[:count].to_i # TODO check this
    params.sides = 1
    params.keep  = nil
    params.mul   = 1
    params.add   = 0

    dice_spec[:tokens].each do |type, val|
      type = tokens[type]
      params.send(:"#{type.to_s}=", val.to_i)
    end

    # Rolling.
    dice = Array.new(params.count).map do
      rand(params.sides) + 1
    end

    if params.keep
      dice = dice.sort.first params.keep
    end

    result = dice.reduce &:+

    result = result * params.mul
    result = result + params.add

    {
      result: result,
      dice:   dice
    }
  end
end
