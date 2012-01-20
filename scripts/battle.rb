
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
#

def initialize
  register_script("IRC role-play battle tracker.")

  register_command("battle", :cmd_battle, 1, 0, "Start, stop, or reset the battle in the current channel. Parameters: START|STOP|RESTART")
  register_command("health", :cmd_health, 0, 0, "View the health of all active players in this channel.")
  register_command("heal",   :cmd_heal,   1, 2, "Heal players to maximum health. If no nick is given, all players are reset. Parameters: nick")

  register_event("PRIVMSG", :on_privmsg)
  
  @active = Hash.new
end

def cmd_battle(msg, params)
  if msg.private?
    msg.reply("You may only battle in channels.")
    return
  end

  case params[0].upcase

  when "START"

    if @active.has_key? msg.destination
      msg.reply("There is already an active battle in \02#{msg.destination}\02")
      return
    end

    start_battle(msg)

  when "STOP"

    unless @active.has_key? msg.destination
      msg.reply("There is no active battle in \02#{msg.destination}\02")
      return
    end

    @active.delete(msg.destination)

    msg.reply("The battle in \02#{msg.destination}\02 has been ended by \02#{msg.nick}\02", false)

  when "RESTART"

    unless @active.has_key? msg.destination
      msg.reply("There is no active battle in \02#{msg.destination}\02")
      return
    end

    @active[msg.destination] = Hash.new

    msg.reply("The battle in \02#{msg.destination}\02 has been restarted by \02#{msg.nick}\02.", false)

  else

    msg.reply("Unknown action. Parameters: START|STOP|RESTART")

  end
end


def start_battle(msg)
  @active[msg.destination] = Hash.new

  msg.reply("\02#{msg.nick}\02 has started a battle!")
  msg.reply("To attack other players, use \02/me attacks TARGET with ITEM\02")
  msg.reply("You may check the health of active players by using the \02HEALTH\02 command.")
end


def get_health(msg, target)
  return @active[msg.destination][target] if @active[msg.destination].include? target

  return get_config("start_health", 100)
end


def set_health(msg, target, health)
  @active[msg.destination][target] = health
end


def heal_player(msg, target)
  set_health(msg, target, get_config("start_health", 100))
end


def attack_player(msg, target, weapon)
  current = get_health(msg, target)
  my_health = get_health(msg, msg.nick)

  if my_health == 0
    msg.reply("You cannot attack when dead.")
    return
  end

  if current == 0
    msg.reply("#{target} is already dead.", false)
    return
  end

  damage = get_config("min_dmg", 5).to_i + rand(get_config("max_dmg", 25).to_i - get_config("min_dmg", 5).to_i)

  new = current - damage
  new = 0 if new < 0

  set_health(msg, target, new)

  if rand(100) < get_config("miss", 10).to_i

    msg.reply("#{target} dodges #{msg.nick}'s #{weapon}.", false)

  elsif damage > 0

    msg.reply("#{msg.nick}'s #{weapon} hits #{target} for \02#{damage} damage\02.", false)

    if new == 0
      msg.reply("#{target} has been defeated!", false)

    else 
      msg.reply("#{target} has \02#{new}\02 health remaining.", false)

    end

  elsif damage < 0

    msg.reply("#{target} absorbs the hit and \02gains #{(damage*-1)} health!\2", false)
    msg.reply("#{target} has \02#{new}\02 health remaining.", false)

  else

    msg.reply("#{msg.nick}'s #{weapon} is completely ineffective.", false)

  end
end

def cmd_health(msg, params)

  unless @active.has_key? msg.destination
    msg.reply("There is no active battle in \02#{msg.destination}\02")
    return
  end

  msg.raw("NOTICE #{msg.nick} :There are currently \02#{@active[msg.destination].keys.length}\02 players in \02#{msg.destination}\02:")

  @active[msg.destination].each { |player, health|
    msg.raw("NOTICE #{msg.nick} :\02#{sprintf("%31.31s", player)}\02 #{health} HP")
  }

  msg.raw("NOTICE #{msg.nick} :End of list.")

end

def cmd_heal(msg, params)

  unless @active.has_key? msg.destination
    msg.reply("There is no active battle in \02#{msg.destination}\02")
    return
  end

  unless @active[msg.destination].include? params[0]
    msg.reply("There is no player #{params[0]} that can be healed.")
    return
  end

  heal_player(msg, params[0])
  msg.reply("#{msg.nick} has healed \02#{params[0]}\02!", false)
  
end

def on_privmsg(msg)
  return if msg.private? or msg.silent? or not @active.has_key? msg.destination

  if msg.text =~ /\01ACTION atta[^ ]+ (.*) with (.*)\01/
    attack_player(msg, $1, $2)
  end

end
