#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'thread'

class Scheduler

  attr_reader :schedule

  def initialize(configClass)
    @configClass = configClass
    @schedule = Array.new

    $log.debug('scheduler') { "Class initialized." }
  end

  def add(name, task, time, repeat = false)

    newItem = ScheduleItem.new(name, task, time, repeat)

    @schedule << newItem

    $log.debug('scheduler') { "New task \"#{name}\" added to run at #{time}#{" and repeat" if repeat}." }

    return newItem

  end

  def start

    Thread.new {
      # Wake up every second, check for tasks, perform those due,
      # then go back to sleep.
      $log.debug('scheduler') { "Thread started." }

      previousTime = 0

      while true

        sleep 1.0 - previousTime # Subtract previous execution time to
                               # try to get us close to just one second
                               # of sleep time.
        now = Time.now.to_i

        begin
          @schedule.each { |item|
            if (item.time <= now and not item.repeat) or (item.repeat and now % item.time == 0)
            
              $log.debug('scheduler') { "Running scheduled task \"#{item.name}\"." }

              item.task.call rescue log.error('scheduler') { "\"#{item.name}\" failed." }

              @schedule.delete item unless item.repeat
            end
          }
        rescue => e
          log.error('scheduler') { "Scheduler failed while looping through items!" }
        end

        previousTime = now - Time.now.to_i
        previousTime = 1.0 if previousTime > 1.0
      end

    }
    rescue $log.error('scheduler') { "Thread ended." }

  end

end
