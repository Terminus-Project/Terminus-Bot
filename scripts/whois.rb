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

require 'em-whois'

register 'View domain registration information.'

command 'whois', 'Look up domain registration information.' do
  argc! 1

  domain = @params.first

  # em-whois inside eventmachine wants to use fibers, so we need to pass a
  # block to synchrony
  EM.synchrony do
    result = Whois.whois domain

    if result.available?
      reply "\02#{domain}\02 is not registered."
      next
    end

    registrants = result.properties[:registrant_contacts].map do |c|
      "#{c[:name]}#{" (#{c[:organization]})" if c[:organization]}"
    end

    registrants = "\02Registrant#{'s' if registrants.length > 1}:\02 #{registrants.join(', ')}"

    creation    = "\02Created:\02 #{result.properties[:created_on]}"
    expiry      = "\02Expires:\02 #{result.properties[:expires_on]}"

    registrar   = "\02Registrar:\02 #{result.properties[:registrar][:name]}"

    domain      = "\02#{result.properties[:domain]}\02:"

    reply [domain, creation, expiry, registrar, registrants].join(' ')
  end
end

