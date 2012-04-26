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

require 'dnsruby'

def initialize
  register_script("Perform DNS look-ups.")

  register_command("dns",  :cmd_dns,   1,  0, nil, "Perform a DNS look-up. Parameters: [type] host_name")
  register_command("rdns", :cmd_rdns,  1,  0, nil, "Perform a reverse DNS look-up.")
end

def cmd_dns(msg, params)
  arr = params[0].split
  type = "ANY"

  if arr.length > 1
    type = arr.shift
  end

  addr = arr.shift

  $log.debug("dns.cmd_dns") { type + " " + addr }

  resolv = Dnsruby::DNS.new()

  begin
    results = resolv.getresources(addr, type)

    if results.empty?
      msg.reply("No results.")
      return
    end

    msg.reply((results.map {|r| r.rdata_to_string.gsub(/[[:cntrl:]]/, '') }).join(", "))
  rescue => e
    msg.reply("Look-up Failed: #{e.to_s.split("::")[1]}")
  end
end

def cmd_rdns(msg, params)
  resolv = Dnsruby::DNS.new()

  begin
    results = resolv.getnames(params[0])

    if results.empty?
      msg.reply("No results.")
      return
    end

    msg.reply((results.map {|r| r.to_s }).join(", "))
  rescue => e
    msg.reply("Look-up Failed: #{e.to_s.split("::")[1]}")
  end
end

