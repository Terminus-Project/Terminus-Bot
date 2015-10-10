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

  user_choice = @params.first.downcase.chr

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
