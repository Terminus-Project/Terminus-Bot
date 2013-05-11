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

require 'multi_json'

need_module! 'http'
need_module! 'url_handler'

register 'Fetch information from GitHub.'

url /\/\/(www\.)?github\.com\/[^\/]+\/[^\/]+/ do
  $log.info('github.url') { @uri.inspect }

  match = @uri.path.match(/^\/(?<owner>[^\/]+)\/(?<project>[^\/]+)(\/(?<action>[^\/]+)\/(?<path>.*))?/)

  # XXX - hmm, might miss some URLs
  next unless match

  if match[:action]

    case match[:action]
    when 'commit'
      get_commit match
    when 'blob'
      if @uri.fragment and @uri.fragment.match(/L([0-9]+)/)
        get_file_line match, $1.to_i
      else
        get_file match
      end
    end

  else

    get_repo match
  end
end

helpers do
  def get_commit match
    path = "/git/commits/#{match[:path]}"

    api_call match[:owner], match[:project], 'repos', path do |data|
      reply "\02#{match[:project]}\02: #{data['message'].lines.first} - by #{data['author']['name']} at #{Time.parse(data['author']['date']).to_s}", false
    end
  end

  def get_file match
    branch, path = match[:path].split('/', 2)
    path = "/contents/#{path}?ref=#{branch}"

    api_call match[:owner], match[:project], 'repos', path do |data|
      reply "\02#{match[:project]}\02: #{data['name']}: #{data['size'].to_f.round / 1024} KiB #{data['type']}", false
    end
  end

  def get_file_line match, line
    if line < 1 # line numbers are 1+ in url
      raise 'line number must be > 0'
    end

    branch, path = match[:path].split('/', 2)
    path = "/contents/#{path}"
    opts = { :head => { 'Accept' => 'application/vnd.github.raw' } }

    uri = URI("https://api.github.com/repos/#{match[:owner]}/#{match[:project]}#{path}")

    http_get uri, {:ref => branch}, true, opts do |http|
      lines = http.response.lines

      if line > lines.length
        raise "line number is too large: #{line} requested, #{lines.length} available"
      end

      result = lines[line - 1]

      result.gsub! /[[:cntrl:]]/, ''

      reply "\02Line #{line}\02: #{result}", false
    end
  end


  def get_repo match
    api_call match[:owner], match[:project], 'repos' do |data|
      reply "\02#{match[:project]}\02 (#{data['language']}): #{data['description']} - by #{data['owner']['login']}", false
    end
  end


  def api_call owner, project, type, path = '', opts = {}
    uri = URI("https://api.github.com/#{type}/#{owner}/#{project}#{path}")

    http_get uri, opts, true do |http|
      yield MultiJson.load http.response
    end
  end
end

# vim: set tabstop=2 expandtab:
