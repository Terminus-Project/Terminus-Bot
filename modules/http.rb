#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Bot
  def self.http_get(uri, limit = Config[:modules][:http][:redirects], redirected = false)
    return nil if limit == 0

    response = Net::HTTP.start(uri.host, uri.port,
                               :use_ssl => uri.scheme == "https",
                               :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      http.request Net::HTTP::Get.new(uri.request_uri)
    
    end

    case response

    when Net::HTTPSuccess
      return [:response => response, :hostname => uri.hostname, :redirected => redirected]

    when Net::HTTPRedirection
      location = URI(response['location'])

      $log.debug("Bot.http_get") { "Redirection: #{uri} -> #{location} (#{limit})" }

      return get_page(location, limit - 1, true)

    else
      return nil

    end
  end
end
