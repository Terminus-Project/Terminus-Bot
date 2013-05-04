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

require 'dnsruby'

register 'Perform DNS look-ups.'

command 'dns', 'Perform a DNS look-up. Parameters: [type] host_name' do
  argc! 1

  arr = @params.first.split
  type = "ANY"

  if arr.length > 1
    type = arr.shift
  end

  addr = arr.shift

  $log.debug("dns.cmd_dns") { type + " " + addr }

  resolv = Dnsruby::DNS.new

  begin
    results = resolv.getresources addr, type

    if results.empty?
      reply "No results."
      next
    end

    reply (results.map {|r| r.rdata_to_string.gsub(/[[:cntrl:]]/, '') }).join(", ")
  rescue => e
    reply "Look-up Failed: #{e.to_s.split("::")[1]}"
  end
end

command 'rdns', 'Perform a reverse DNS look-up.' do
  argc! 1

  resolv = Dnsruby::DNS.new

  begin
    results = resolv.getnames @params.first

    if results.empty?
      reply "No results."
      next
    end

    reply (results.map {|r| r.to_s }).join(", ")
  rescue => e
    reply "Look-up Failed: #{e.to_s.split("::")[1]}"
  end
end

# vim: set tabstop=2 expandtab:
