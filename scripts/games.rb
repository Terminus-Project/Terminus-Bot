#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco,
# David Farrell <shokku.ra@gmail.com> (http://terminus-bot.net/)
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

register 'Provides several game commands.'


command 'dice', 'Roll dice. Parameters: <count>d<sides>[+/-<modifier> | s<success>[b<botch>]] [order]' do
  argc! 1

  order = false
  params = @params.shift.split

  match = params.shift.match(/\A(?<count>[0-9]+)?(d(?<sides>[0-9]+))?((?<mod>[+-][0-9]+)|(s(?<success>[0-9])+(b(?<botch>[0-9])+)?))?\Z/)

  unless match
    raise 'Syntax: <count>d<sides>[+/-<modfier> | s<success>[b<botch>]] [order]'
  end

  count   = (match[:count] or 1).to_i
  sides   = (match[:sides] or 6).to_i
  mod     = match[:mod].to_i
  success = match[:success].to_i
  botch   = match[:botch].to_i

  if count > 100
    raise 'You may only roll up to 100 dice.'
  end

  if sides > 100
    raise 'Dice may only have up to 100 sides.'
  end

  if count <= 0 or sides <= 0
    raise 'The number of dice and their sides must be positive numbers larger than 0.'
  end

  if match[:success] and botch > success
    raise 'The success target must be greater than the botch target.'
  end

  params.each do |param|
    if param == 'order'
      order = true
      break
    end
  end

  if order and match[:success]
    raise 'Cannot count successes/botches and roll dice in order.'
  end

  if order
    rolls = []
    sum   = mod

    count.times do |i|
      rolls[i] = rand(sides) + 1
      sum += rolls[i]
    end

    reply "#{rolls.join(', ')} #{"Modifier: #{mod} " unless mod.zero?}\02Sum: #{sum}\02"

  elsif success and not success.zero?
    num_success = 0
    num_botch   = 0

    count.times do
      r = rand(sides) + 1
      if r >= success
        num_success += 1
      elsif botch != 0 and r <= botch
        num_botch += 1
      end
    end

    if botch.zero?
      reply "Rolled #{num_success} successes and #{num_botch} botches."
    else
      reply "Rolled #{num_success} successes."
    end

  else
    rolls  = Hash.new 0
    output = []
    sum    = mod

    count.times { rolls[rand(sides)+1] += 1 }

    rolls.each_pair do |r, c|
      output << "#{r}#{(c > 1 ? "x#{c}" : '')}"
      sum += r * c
    end

    reply "#{output.sort.join(', ')} #{"Modifier: #{mod} " unless mod.zero?}\02Sum: #{sum}\02"
  end
end

command 'eightball', 'Shake the 8-ball.' do
  reply [
    'Most likely',                'It is certain',
    'As I see it, yes',           'Signs point to yes',
    'Outlook Good',               'It is decidedly so',
    'My sources say Yes',         'Yes, Definetly',
    'Without a doubt',            'You may rely on it',
    'YES',                        'Very doubtful',
    'My sources say NO',          'My reply is NO',
    'Don\'t count on it',         'Outlook not so good',
    'Concentrate and ask again',  'Cannot predict now',
    'Reply hazy, try again',      'Ask again later',
    'Better not tell you now'
  ].sample
end

command 'coin', 'Flip a coin.' do
  reply %w[Heads Tails].sample
end

command 'rps', 'Play Rock-paper-scissors. Syntax: rock|paper|scissors' do
  argc! 1

  choices = {
    'r' => 'rock',
    'p' => 'paper',
    's' => 'scissors'
  }

  user_choice = @params.first.downcase[0]

  unless choices.has_key? user_choice
    raise 'Valid choices are rock, paper, or scissors.'
  end

  own_choice = choices.keys.sample

  case user_choice
  when own_choice
    
    reply "I picked \02#{choices[own_choice]}\02 - it's a draw!"

  when 'r'

    case own_choice
    when 'p'
      reply 'Paper covers rock. I win!'
    when 's'
      reply 'Scissors blunted by paper... I lose.'
    end

  when 'p'

    case own_choice
    when 's'
      reply 'Scissors cut paper. I win!'
    when 'r'
      reply 'Rock covered by paper... I lose.'
    end

  when 's'
    case own_choice
    when 'r'
      reply 'Rock blunts scissors. I win!'
    when 'p'
      reply 'Paper cut by scissors... I lose.'
    end

  end
end

# vim: set tabstop=2 expandtab:
