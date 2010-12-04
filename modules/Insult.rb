
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
  registerModule("Insult", "Hate generator.")

  registerCommand("Insult", "insult", "Be mean. If a target is given, I will insult the target.", "target")
end

def cmd_insult(message)
  # We'll populate word arrays here rather than when the module is
  # initialized so we don't just hold them in memory 24/7.
  
  if message.args.empty?
    victims = [ "You are", "Your mother is", "Your father is", "Your grandmother is" ]
  else
    victims = [ "#{message.args} is", "#{message.args}'s mother is", "#{message.args}'s father is", "#{message.args}'s grandmother is" ]
  end

  adjectives1 = [ "slow", "fat", "stupid", "dumb", "lazy", "ugly", "boring", "uninteresting", "talentless", "anal" ]
  adjectives2 = [ "slutty", "incestuous", "sheep-loving", "tree-humping", "goat-loving" ]
  nouns = [ "dipshit", "dumbass", "idiot", "fool", "demon", "queef", "douchebag", "bastard", "pedophile", "twat", "fart" ]

  victim = arrRand(victims)
  adj1 = arrRand(adjectives1)
  adj2 = arrRand(adjectives2)
  noun = arrRand(nouns)

  a = "a"

  a << "n" if ["a","e","i","o","u"].include? adj1[0]

  insult = "#{victim} #{a} #{adj1}, #{adj2} #{noun}."

  reply(message, insult, false)

end

def arrRand(arr)
  return arr[rand(arr.length)]
end
