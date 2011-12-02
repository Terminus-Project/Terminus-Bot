#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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


module Terminus_Bot
  class Database

    require 'psych'

    FILENAME = DATA_DIR + "data.db"

    # Read the database if it exists. Otherwise, write an empty database.
    def initialize
      @data = Hash.new

      if File.exists? FILENAME
        read_database
      else
        write_database
      end

      # Try to make sure we write our database before we exit.
      at_exit { write_database }
    end

    # Read the database into the @data structure. This should be
    # a hash table, since we initialize it as one and write it the first
    # time we run.
    def read_database
      @data = Psych.load(IO.read(FILENAME))
    end

    # Write @data converted to YAML to FILENAME.
    def write_database
      Dir.mkdir("var") unless Dir.exists? "var"
      Dir.mkdir("var/terminus-bot") unless Dir.exists? "var/terminus-bot"

      File.open(FILENAME, "w") { |f| f.write(@data.to_yaml)}
    end


    # Implement a few Hash methods.
    # TODO: Make this less dumb. Maybe can extend Hash somehow.
    #       Not really sure how exactly to do that. We could just
    #       pass the method calls to @data if with method_missing but
    #       that is pretty dorky. And I'm not sure how to extend
    #       Hash and still be able to call Psych.load.

    def [](key)
      return @data[key]
    end

    def []=(key, val)
      @data[key] = val
    end

    def delete(key)
      @data.delete(key)
    end

    def to_s
      return @data.to_s
    end

    def has_key?(key)
      @data.has_key? key
    end
  end
end
