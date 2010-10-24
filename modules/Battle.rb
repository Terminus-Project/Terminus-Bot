
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
  $bot.modHelp.registerModule("Battle", "IRC role-play battle tracker.")

  $bot.modHelp.registerCommand("Battle", "battle", "Start or stop the battle in the current channel.", "")
  $bot.modHelp.registerCommand("Battle", "health", "View the health of all active players in this channel.", "")
  $bot.modHelp.registerCommand("Battle", "heal", "Heal players to maximum health. If no nick is given, all players are reset.", "nick")
  #$bot.modHelp.registerCommand("Battle", "", "", "")
  #$bot.modHelp.registerCommand("Battle", "", "", "")

  @active = Hash.new
  $bot.modConfig.put("battle", "startingHP", 1000) if $bot.modConfig.get("battle", "startingHP") == nil 
  $bot.modConfig.put("battle", "maxDamage", 225) if $bot.modConfig.get("battle", "maxDamage") == nil 
  $bot.modConfig.put("battle", "minDamage", -50) if $bot.modConfig.get("battle", "minDamage") == nil 
  $bot.modConfig.put("battle", "missChance", 20) if $bot.modConfig.get("battle", "missChance") == nil 
end

def cmd_battle(message)
  unless $bot.network.isChannel? message.destination
    reply(message, "You can only battle in channels.")
    return true
  end

  if @active.keys.include? message.destination

    @active.delete(message.destination)
    reply(message, "#{BOLD}#{message.speaker.nick}#{NORMAL} has ended the battle.")

  else

    @active[message.destination] = Hash.new

    reply(message, "#{BOLD}#{message.speaker.nick}#{NORMAL} has started a battle!")
    reply(message, "To attack other players, use #{BOLD}/me attacks TARGET with ITEM#{NORMAL}")
    reply(message, "You may check the health of active players by using the #{BOLD}health#{NORMAL} command.")

  end
end

def checkActive(message)
  unless @active.keys.include? message.destination
    reply(message, "There is not a battle currently taking place in this channel. To start one, use the #{BOLD}battle#{NORMAL} command.")
    return false
  end

  return true
end

def getHealth(message, target)
  chan = message.destination

  return @active[chan][target] if @active[chan].include? target

  return $bot.modConfig.get("battle", "startingHP")
end

def setHealth(message, target, health)
  chan = message.destination

  @active[chan][target] = Integer(health)
end

def healPlayer(message, target)
  setHealth(message, target, $bot.modConfig.get("battle", "startingHP"))
end

def attackPlayer(message, target, weapon)
  current = getHealth(message, target)

  if current == 0
    reply(message, "#{target} is already dead.", false)
  end

  damage = $bot.modConfig.get("battle", "minDamage") + rand($bot.modConfig.get("battle", "maxDamage")-$bot.modConfig.get("battle", "minDamage"))

  new = current - damage
  new = 0 if new < 0

  setHealth(message, target, new)

  if rand(100) < Integer($bot.modConfig.get("battle", "missChance"))
    reply(message, "#{target} dodges #{message.speaker.nick}'s #{weapon}.", false)
  elsif damage > 0
    reply(message, "#{message.speaker.nick}'s #{weapon} hits #{target} for #{BOLD}#{damage} damage#{NORMAL}.", false)

    if new == 0
      reply(message, "#{target} has been defeated!", false)
      #reply(message, "", false)
    else 
      reply(message, "#{target} has #{BOLD}#{new}#{NORMAL} health remaining.", false)
      #reply(message, "", false)
    end

  elsif damage < 0
    reply(message, "#{target} absorbs the hit and #{BOLD}gains #{(damage*-1)} health!#{NORMAL}", false)
    reply(message, "#{target} has #{BOLD}#{new}#{NORMAL} health remaining.", false)
    #reply(message, "", false)
  else
    reply(message, "#{message.speaker.nick}'s #{weapon} is completely ineffective.", false)
  end
end

def cmd_health(message)
  return true unless checkActive(message)
  
  sendNotice(message.speaker.nick, "There are currently #{@active[message.destination].keys.length} players in #{message.destination}.")

  @active[message.destination].each { |player, health|
    sendNotice(message.speaker.nick, "#{player}: #{health} HP")
  }
end

def cmd_heal(message)
  return true unless checkActive(message) and message.speaker.adminLevel > 2

  if message.args.empty?
    @active[message.destination].each { |player, health|
      healPlayer(message, player)
    }
    reply(message, "#{message.speaker.nick} has healed all players!", false)
  else
    healPlayer(message, message.args)
    reply(message, "#{message.speaker.nick} has healed #{BOLD}#{message.args}#{NORMAL}!", false)
  end
  
end

def bot_ctcpRequest(message)
  return true unless @active.keys.include? message.destination

  if message.message =~ /ACTION atta[^ ]+ (.*) with (.*)/
    attackPlayer(message, $1, $2)
  end

end
