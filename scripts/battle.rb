#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2014 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# Rylee Fowler <rylee@rylee.me> (http://terminus-bot.net/)
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

register 'IRC role-play battle tracker.'

@@active = {}

command 'battle', 'Start, stop, or reset the battle in the current channel. Parameters: START|STOP|RESTART' do
  channel! and half_op! and argc! 1

  case @params[0].upcase

  when "START"

    if @@active.key? @msg.destination_canon
      reply "There is already an active battle in \02#{@msg.destination}\02"
      next
    end

    start_battle

  when "STOP"

    unless @@active.key? @msg.destination_canon
      reply "There is no active battle in \02#{@msg.destination}\02"
      next
    end

    @@active.delete @msg.destination_canon

    reply "The battle in \02#{@msg.destination}\02 has been ended by \02#{@msg.nick}\02", false

  when "RESTART"

    unless @@active.key? @msg.destination_canon
      reply "There is no active battle in \02#{@msg.destination}\02"
      next
    end

    @@active[@msg.destination_canon] = {}

    reply "The battle in \02#{@msg.destination}\02 has been restarted by \02#{@msg.nick}\02.", false

  else

    reply "Unknown action. Parameters: START|STOP|RESTART"

  end
end


command 'health', 'View the health of all active players in this channel.' do

  unless @@active.key? @msg.destination_canon
    reply "There is no active battle in \02#{@msg.destination}\02"
    next
  end

  send_notice @msg.nick, "There are currently \02#{@@active[@msg.destination_canon].keys.length}\02 players in \02#{@msg.destination}\02:"

  @@active[@msg.destination_canon].each do |player, health|
    send_notice @msg.nick, "\02#{sprintf("%31.31s", player)}\02 #{health} HP"
  end

  send_notice @msg.nick, "End of list."

end

command 'heal', 'Heal players to maximum health. If no nick is given, all players are reset. Parameters: nick' do
  channel! and half_op! and argc! 1

  unless @@active.key? @msg.destination_canon
    reply "There is no active battle in \02#{@msg.destination}\02"
    next
  end

  target = @connection.canonize @params[0]

  unless @@active[@msg.destination_canon].include? target
    reply "There is no player #{@params[0]} that can be healed."
    next
  end

  heal_player target
  reply "#{@msg.nick} has healed \02#{@params[0]}\02!", false

end


event :PRIVMSG do
  next if query? or not @@active.key? @msg.destination_canon

  if @msg.text =~ /\01ACTION (atta|hit)[^ ]+ (.*?) with (.*)\01/i
    attack_player $2, $3
  end
end

helpers do
  def start_battle
    @@active[@msg.destination_canon] = {}

    reply "\02#{@msg.nick}\02 has started a battle!", false
    reply "To attack other players, use \02/me attacks TARGET with ITEM\02", false
    reply "You may check the health of active players by using the \02HEALTH\02 command.", false
  end


  def get_health target
    return @@active[@msg.destination_canon][target] if @@active[@msg.destination_canon].include? target

    get_config(:start_health, 100).to_i
  end


  def set_health target, health
    @@active[@msg.destination_canon][target] = health
  end


  def heal_player target
    set_health target, get_config(:start_health, 100)
  end


  def attack_player target, weapon
    original = target
    target = @connection.canonize target

    if target == @connection.canonize(@connection.nick)
      reply "You can't attack me!"
      return
    end
    unless @connection.channels[@msg.destination_canon].users.key? target
      reply "There is no such user in the channel."
      return
    end

    current = get_health target
    my_health = get_health @connection.canonize(@msg.nick)

    if my_health == 0
      reply "You cannot attack while dead."
      return
    end

    if current == 0
      reply "#{original} is already dead.", false
      return
    end

    damage = get_config(:min_dmg, 5).to_i + rand(get_config(:max_dmg, 25).to_i - get_config(:min_dmg, 5).to_i)

    if rand(100) <= get_config(:absorb, 5).to_i
      damage = damage * -1
    end

    new = current - damage
    new = 0 if new < 0

    if rand(100) < get_config(:miss, 10).to_i
      reply "#{original} dodges #{@msg.nick}'s #{weapon}.", false
      return
    end

    set_health target, new

    if damage > 0
      reply "#{@msg.nick}'s #{weapon} hits #{original} for \02#{damage} damage\02.", false

      if new == 0
        reply "#{original} has been defeated!", false
        if half_op? @connection.nick and get_config(:kick_on_death, false)
          send_kick @msg.destination, original, "You've just been slain by #{@msg.nick} with #{weapon}!"
        end

      else
        reply "#{original} has \02#{new}\02 health remaining.", false

      end

      return
    end

    if damage < 0
      reply "#{original} absorbs the hit and \02gains #{(damage*-1)} health!\2", false
      reply "#{original} has \02#{new}\02 health remaining.", false

      return
    end

    reply "#{@msg.nick}'s #{weapon} is completely ineffective.", false

  end
end
# vim: set tabstop=2 expandtab:
