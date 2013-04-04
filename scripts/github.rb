#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
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

require "json"

raise "github script requires the url_handler module" unless defined? MODULE_LOADED_URL_HANDLER

register 'Fetch information from GitHub.'

url /\/\/(www\.)?github\.com\/[^\/]+\/[^\/]+/ do
  $log.info('github.url') { @uri.inspect }

  match = @uri.path.match(/^\/(?<owner>[^\/]+)\/(?<project>[^\/]+)(\/(?<action>[^\/]+)\/(?<hash>[^\/]+))?/)

  # XXX - hmm, might miss some URLs
  next unless match

  if match[:action]

    case match[:action]
    when 'commit'
      get_commit match
    end
  else

    get_repo match
  end
end

helpers do
  def get_commit match
    api = URI("https://api.github.com/repos/#{match[:owner]}/#{match[:project]}/git/commits/#{match[:hash]}")

    http_get(api, {}, true) do |http|
      data = JSON.parse http.response

      reply "\02#{match[:project]}\02: #{data["message"].lines.first} - by #{data["author"]["name"]} at #{Time.parse(data["author"]["date"]).to_s}", false
    end
  end

  def get_repo match
    api = URI("https://api.github.com/repos/#{match[:owner]}/#{match[:project]}")

    http_get(api, {}, true) do |http|
      data = JSON.parse http.response

      reply "\02#{match[:project]}\02 (#{data["language"]}): #{data["description"]} - by #{data["owner"]["login"]}", false
    end
  end
end

