#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

def initialize
  register_script "Provides several game commands."

  register_command "dice",        :cmd_dice,       1,  0, nil, "Roll dice. Parameters: <count>d<sides>[+/-<modifier> | s<success>[b<botch>]] [order]"
  register_command "eightball",   :cmd_eightball,  0,  0, nil, "Shake the 8-ball."
  register_command "coin",        :cmd_coin,       0,  0, nil, "Flip a coin."
end

def cmd_dice msg, params

  order = false

  unless params.shift =~ /\A([0-9]+)d([0-9]+)(([+-][0-9]+)|(s([0-9])+(b([0-9])+)?))?\Z/
    msg.reply "Syntax: <count>d<sides>[+/-<modfier> | s<success>[b<botch>]] [order]"
    return
  end

  count = $1.to_i
  sides = $2.to_i
  mod   = $4.to_i
  success = $6.to_i
  botch = $8.to_i

  if count > 100
    msg.reply "You may only roll up to 100 dice."
    return
  end

  if sides > 100
    msg.reply "Dice may only have up to 100 sides."
    return
  end

  if count <= 0 or sides <= 0
    msg.reply "The number of dice and their sides must be positive numbers larger than 0."
    return
  end

  unless success <= botch
    msg.reply "The success target must be greater than the botch target."
    return
  end

  params.each do |param|
    if param == "order"
      order = true
    end
  end

  unless not ( order and success )
    msg.reply "Cannot count successes/botches and roll dice in order."
    return
  end

  if order
    rolls = Array.new
    sum = mod

    count.times do |i|
      rolls[i] = rand(sides) + 1
      sum += rolls[i]
    end

    msg.reply "#{rolls.join(", ")} #{"Modifier: #{mod}" unless mod.zero?} \02Sum: #{sum}\02"
  elsif success != 0
    num_success = 0
    num_botch = 0

    count.times do
      r = rand(sides) + 1
      if r >= success
        num_success += 1
      elsif botch != 0 and r <= botch
        num_botch += 1
      end
    end

    if botch != 0
      msg.reply "Rolled #{num_success} successes."
    else
      msg.reply  "Rolled #{num_success} successes and #{num_botch} botches."
    end
  else
    rolls  = Hash.new 0
    output = Array.new
    sum    = mod

    count.times { rolls[rand(sides)+1] += 1 }

    rolls.each_pair { |r, c|
      output << "#{r}#{(c > 1 ? "x#{c}" : "")}"
      sum += r * c
    }

    msg.reply "#{output.sort.join(", ")} #{"Modifier: #{mod}" unless mod.zero?} \02Sum: #{sum}\02"
  end
end

def cmd_eightball msg, params
  msg.reply [ "Most likely" ,   "It is certain",
    "As I see it, yes",         "Signs point to yes",
    "Outlook Good",             "It is decidedly so",
    "My sources say Yes ",      "Yes, Definetly",
    "Without a doubt",          "You may rely on it",
    "YES",                      "Very doubtful",
    "My sources say NO",        "My reply is NO",
    "Don't count on it",        "Outlook not so good",
    "Concentrate and ask again","Cannot predict now",
    "Reply hazy, try again",    "Ask again later",
    "Better not tell you now" ].sample
end

def cmd_coin msg, params
  msg.reply ["Heads", "Tails"].sample
end

