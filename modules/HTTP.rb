require "net/http"
require "uri"
require "strscan"


class HTTP

  def cmd_title(message)
    if message.args =~ /(https?:\/\/.+\..*)/
      $log.debug('http') { "Getting title for #{$1}" }

      page = StringScanner.new(Net::HTTP.get URI.parse($1))

      page.skip_until(/<title>/i)
      title = page.scan_until(/<\/title>/i)
      title = title[0..title.length - 9].gsub(/\n/, " ").gsub(/^\s+/,"").gsub(/\s+$/, "").gsub(/\s+/, " ") rescue "I was unable to determine the title of the page."
      
      reply(message, title, true)
       
    else
      reply(message, "That doesn't look like a valid HTTP URL.", true)
    end
  end

end

$modules.push(HTTP.new)
