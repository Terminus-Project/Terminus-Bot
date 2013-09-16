# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco,
# Marshall Fowler (http://terminus-bot.net/), Jade Rain
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

register 'Converts decimal to hexadecimal and vice versa.'

command 'hex', 'Converts a hexadecimal number prefixed with 0x to decimal and a decimal number to hexadecimal.' do
	argc! 1
	
	number = @params.first
	
	if(number.start_with?("0x"))
		number.slice! "0x"
		reply number.to_i(16).to_s(10)
	else
		reply number.to_i(10).to_s(16)
	
	end
end

register 'Converts a base to another base.'

command 'base', 'Converts a base to another base. Parameters: [number] [base of number] [new base]' do
	argc! 3
	
	number = @params.first(1)
	old_base = @params.first(2)
	new_base = @params.first(3)
	
	reply number.to_i(old_base.to_i).to_s(new_base.to_i)
end
