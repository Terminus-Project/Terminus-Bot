#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Convert text to various alphabets'

command 'nato', 'Convert text to the NATO phonetic alphabet.' do
  argc! 1

  nato = [
    'Alpha',  'Bravo',    'Charlie',  'Delta',  'Echo',     'Foxtrot', 
    'Golf',   'Hotel',    'India',    'Juliet', 'Kilo',     'Lima',   
    'Mike',   'November', 'Oscar',    'Papa',   'Quebec',   'Romeo',  
    'Sierra', 'Tango',    'Uniform',  'Victor', 'Whiskey',  'Xray',
    'Yankee', 'Zulu'
  ]
  
  reply @params.first.upcase.scan(/[A-Z]/).map {|c| nato[c.ord-65] }.join(' ')
end

command 'morse', 'Convert text to Morse code.' do
  morse = [
    '',       '',       '',       '',       '',       '',       '',       '',  
    '',       '',       '',       '',       '',       '',       '',       '',  
    '',       '',       '',       '',       '',       '',       '',       '',  
    '',       '',       '',       '',       '',       '',       '',       '',  

    '  ',     '',       '',       '',       '',       '',       '',       '',  
    '',       '',       '',       '',       '',       '',       '',       '',  
    '-----',  '.----',  '..---',  '...--',  '....-',  '.....',  '-....',  '--...',
    '---..',  '----.',  '',       '',       '',       '',       '',       '',  

    '',       '.-',     '-...',   '-.-.',   '-..',    '.',      '..-.',   '--.',  
    '....',   '..',     '.---',   '-.-',    '.-..',   '--',     '-.',     '---',  
    '.--.',   '--.-',   '.-.',    '...',    '-',      '..-',    '...-',   '.--',  
    '-..-',   '-.--',   '--..',   '',       '',       '',       '',       '',  

    '',       '.-',     '-...',   '-.-.',   '-..',    '.',      '..-.',   '--.',  
    '....',   '..',     '.---',   '-.-',    '.-..',   '--',     '-.',     '---',  
    '.--.',   '--.-',   '.-.',    '...',    '-',      '..-',    '...-',   '.--',  
    '-..-',   '-.--',   '--..',   '',       '',       '',       '',       '',  
  ]

  reply @params.join.chars.map { |c| morse[c.ord] if c.ord < 128 }.join(' ')
end

