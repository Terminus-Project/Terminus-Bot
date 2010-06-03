

class ModuleHelp

  def initialize
    @modules = Hash.new
  end

  def commandList
    list = Array.new

    @modules.each_value { |value|
      list << value.commands.keys
    }

    return list
  end

  def moduleList
    @modules.keys
  end

  def registerCommand(owner, command, help, args = nil)
    if @modules[owner] == nil
      $log.error('module_help') { "Cannot register command; module #{owner} must register." }
      return nil
    end

    @modules[owner].addCommand(ModuleHelpCommand.new(command, help, args))
  end

  def registerModule(name, description)
    unless @modules[name] == nil
      $log.error('module_help') { "Cannot register module; module #{owner} has already been registered." }
      return nil
    end

    @modules[name] = ModuleHelpObject.new(name, description)
  end

  def getCommandHelp(name, owner = nil)
    if owner == nil

      @modules.each_value { |mod|
        cmd = mod.getCommand(name)

        unless cmd == nil
          return cmd.to_s
        end

      }

      return nil

    else
      return @modules[owner].getCommand(name).to_s
    end
  end

  def getModuleHelp(name)
    unless @modules[name] == nil
      return @modules[name].description
    else
      return nil
    end
  end

  def unregisterModule(name)
    @modules.delete name
  end

end
