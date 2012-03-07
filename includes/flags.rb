
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

class FlagTable

  # this is just to allow probing with irb; it will be removed
  attr_accessor :scripts, :table


  def initialize(default)
    # these are effectively the columns
    @scripts = [""]

    # and these are the rows
    @table = Hash.new
    @table[["", ""]] = [default]
  end


  def add_server(server)
    @table[[server, ""]] = @table[["",""]].clone
  end

  def add_channel(server, channel)
    @table[[server, channel]] = @table[[server, ""]].clone
  end


  # adds a script column
  def add_script(name)

    # first: add the script to the column array
    idx = @scripts.index(nil)
    if idx
      @scripts[idx] = name
    else
      idx = @scripts.length
      @scripts << name
    end

    # second: add a column to every element of the hash
    @table.each_key do |key|
      @table[key][idx] = @table[key][0]
    end
  end

  # deletes a script column
  def del_script(name)
    idx = @scripts.index(name)
    return unless idx

    # first: clear the script in the column array
    @scripts[idx] = nil if idx

    # second: clear every matching column in every row
    @table.each_key do |key|
      @table[key][idx] = nil
    end
  end


  # iterate over a server:channel and script mask
  def each_key(chanmask, scriptmask)
    # I feel like there's a better way to do this...
    scriptidx = @scripts.select { |name| name.wildcard_match(scriptmask) }
    scriptidx.map! { |name| @scripts.index(name) }

    # iterate over the table.
    @table.each_key do |row|
      if row.join(":").wildcard_match(chanmask)
        scriptidx.each { |col| yield row, col }
      end
    end
  end


  # iterate values of each_masked mask
  def each_value(chanmask, scriptmask)
    self.each_key(chanmask, scriptmask) do |row, col|
      yield @table[row][col]
    end
  end

  # iterate over each_masked mask and assign the return value
  def each_value!(chanmask, scriptmask)
    self.each_key(chanmask, scriptmask) do |row, col|
      @table[row][col] = yield @table[row][col]
    end
  end


end

