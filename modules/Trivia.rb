
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
  $bot.modHelp.registerModule("Trivia", "Trivia games.")

  $bot.modHelp.registerCommand("Trivia", "trivia start", "Begin a trivia game. If a category is specified, questions are restricted to that category. If not, all categories are used.", "category")
  $bot.modHelp.registerCommand("Trivia", "trivia list", "List available trivia categories.", "")
  $bot.modHelp.registerCommand("Trivia", "trivia score", "Show score information. If a player name is provided, detailed information for that player is provided.", "player")
  $bot.modHelp.registerCommand("Trivia", "trivia stop", "End the current trivia game.", "")

  @active = Hash.new
end

def cmd_trivia(message)
  #reply(message, message.args, false)
  
  case message.msgArr[1].downcase
    when "start"

      unless $bot.network.isChannel? message.destination
        reply(message, "Please use this command in a channel.")
        return true
      end

      unless @active.include? message.destination

        if message.msgArr.length == 3

          if message.msgArr[2].include? "."

            reply(message, "That is not a valid category name.")
            return true

          elsif not checkCategory(message.msgArr[2])

            reply(message, "There is no available category with that name.")
            return true

          end
  
          @active[message.destination] = Questions.new(message.msgArr[2])

        else

          @active[message.destination] = Questions.new

        end

      else

        reply(message, "A trivia game is already in progress.")
        return true
      end

      reply(message, "#{message.speaker.nick} has started a new #{BOLD}trivia game!#{NORMAL}", false)

      if message.msgArr.length == 3
        reply(message, "The category for this game is #{BOLD}#{message.msgArr[2]}#{NORMAL}.", false)
      else
        reply(message, "This game will include questions from #{BOLD}all categories#{NORMAL}.", false)
      end

      askQuestion(message.destination)

    when "stop"

      if @active.include? message.destination

        @active.delete(message.destination)

        reply(message, "#{BOLD}#{message.speaker.nick}#{NORMAL} has ended the game.", false)

      else
        reply(message, "There is no trivia game in progress in this channel.")
      end

    when "list"

      replyList = ""

      Dir.foreach("trivia") { |file|
        replyList << "#{file.gsub(".txt", "")}" unless file == "." or file == ".."
      }

      reply(message, replyList)

    when "score"
      reply(message, "This command is not yet implemented.")

  end
end

def bot_privmsg(message)
  return true unless @active.include? message.destination

  if checkAnswer(message)
    reply(message, "Correct!")
    sleep 5
    askQuestion(message.destination)
  end
end

def askQuestion(channel)
  sendPrivmsg(channel, @active[channel].getQuestion)
end

def checkAnswer(message)
  return @active[message.destination].checkAnswer(message.message)
end

def checkCategory(name)
  return (Dir.exists? "trivia" and File.exists? "trivia/#{name}.txt")
end

class Questions

  def initialize(category = "")
    @questions = Hash.new
    @lastQuestion = ""

    if category.empty?

      Dir.foreach("trivia") { |file|

        next if file == "." or file == ".."

        file = "trivia/#{file}"

        if File.exists? file and File.readable? file
          $log.debug('trivia') { "Loading file #{file}" }
          loadQuestions(file)
        else
          $log.error('trivia') { "Error loading file #{file}. Does not exist or is not readable!" }
        end

      }

    else

      file = "trivia/#{category}.txt"

      if File.exists? file and File.readable? file
        $log.debug('trivia') { "Loading file #{file}" }
        loadQuestions(file)
      else
        $log.error('trivia') { "Error loading file #{file}. Does not exist or is not readable!" }
      end

    end

  end

  def loadQuestions(name)
    qfile = File.new(name)

    even = true
    question = ""

    qfile.each { |line|
      if even
        question = line.chomp
      else
        @questions[question] = line.chomp.split("|")
      end

      even = (not even)
    }
  end
  
  def getQuestion
    $log.debug('trivia') { "Getting question." }
    @lastQuestion = @questions.keys[rand(@questions.keys.length-1)]
    $log.debug('trivia') { "Got: #{@lastQuestion}" }
    return @lastQuestion
  end

  def checkAnswer(answer)
    return false if @lastQuestion == nil
    return false if @lastQuestion.empty?

    correct = @questions[@lastQuestion].include? answer.downcase
    @lastQuestion = "" if correct
    return correct
  end

end
