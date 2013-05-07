need_module! 'buffer'

require 'timeout'

register 'Make messages prettier.'

event :PRIVMSG do
  next if query?

  # XXX - fix recognition of escaped slashes
  match = @msg.text.match(/^r\/(?<search>.+?)(\/(?<flags>.*))?$/)

  if match
    next unless Buffer.has_key? @connection.name
    next unless Buffer[@connection.name].has_key? @msg.destination_canon

    rainbows match

    next
  end
end

helpers do
  def rainbows match
    Timeout::timeout(get_config(:run_time, 2).to_i) do
      # match[:replace] is flags because whatever
      search, flags, opts = match[:search], match[:flags], Regexp::EXTENDED

      opts |= Regexp::IGNORECASE if flags and flags.include? 'i'

      search = Regexp.new match[:search].gsub(/\s/, '\s'), opts

      Buffer[@connection.name][@msg.destination_canon].reverse.each do |message|
        next if message[:text].match(/^(r|l|s|g)\/(.+?)\/(.*?)(\/.*)?$/)

        text = Bot.strip_irc_formatting message[:text]

        if search.match text
          text = rainbowify text, flags

          reply_with_match message[:type], message[:nick], text

          return
        end

      end
    end
  end

  def rainbowify str, flags = ''
    random      = flags.include? 'r'
    words       = flags.include? 'w'
    background  = flags.include? 'b'
    line        = flags.include? 'l'

    fg_colors = %w[05 04 07 08 03 09 10 11 02 12 06 13]
    bg_colors = fg_colors.reverse

    if random and line
      fg_color = fg_colors.sample
      bg_color = bg_colors.sample
    else
      fg_color = fg_colors.first
      bg_color = bg_colors.first
    end

    str.each_char.map do |c|
      if c.match(/\s/)
        if words and not line
          fg_color = next_color fg_colors, random
          bg_color = next_color bg_colors, random
        end

        if line
          c
        elsif not line and background
          "\03#{fg_color},#{bg_color}#{c}"
        else
          "\03#{c}"
        end
      else

        if not words and not line
          fg_color = next_color fg_colors, random
          bg_color = next_color bg_colors, random
        end

      "\03#{fg_color}#{",#{bg_color}" if background}#{c}"
      end
    end.join
  end

  def next_color colors, random
    if random
      colors.sample
    else
      colors.rotate!.first
    end
  end

  def reply_with_match type, nick, message
    case type
    when :ACTION
      reply "* #{nick} #{message}", false
    when :PRIVMSG
      reply "<#{nick}> #{message}", false
    when :NOTICE
      reply "-#{nick}- #{message}", false
    end
  end
end

