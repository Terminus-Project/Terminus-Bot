

class ModuleHelpObject

  attr_reader :name, :commands, :description

  def initialize(name, description)
    @name = name
    @description = description
    @commands = Hash.new
  end

  def getCommand(name)
    @commands[name] rescue nil
  end

  def addCommand(commandObj)
    @commands[commandObj.name] = commandObj
  end

end
