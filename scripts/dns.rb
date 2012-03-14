
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


require 'dnsruby'

def initialize
  register_script("Perform DNS look-ups.")

  register_command("dns",  :cmd_dns,   1,  0, "Perform a DNS look-up. Parameters: [type] host_name")
  register_command("rdns", :cmd_rdns,  1,  0, "Perform a reverse DNS look-up.")
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

