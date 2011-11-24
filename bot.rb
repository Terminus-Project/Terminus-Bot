#!/usr/bin/ruby

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


require 'socket'
require 'thread'
require 'logger'

Dir.chdir(File.dirname(__FILE__))

#$log = Logger.new('var/terminus-bot.log', 'weekly');
$log = Logger.new(STDOUT);

puts "Starting..."

def require_files(dir)
  begin
    Dir["#{dir}/**/*.rb"].each { |f| require(f) }
  rescue => e
    $log.fatal('preload') { "Failed loading files in #{dir}: #{e}" }
    exit -1
  end
end

# Load all the includes.
require_files "includes"

# Launch!
# TODO: Fork?
Terminus_Bot::Bot.new

