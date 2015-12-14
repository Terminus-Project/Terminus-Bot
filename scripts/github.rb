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

need_module! 'http', 'url_handler'

register 'Fetch information from GitHub.'

url(/\/\/(www\.)?github\.com\/[^\/]+\/[^\/]+/) do
  $log.info('github.url') { @uri.inspect }

  match = @uri.path.match(/^\/(?<owner>[^\/]+)\/(?<project>[^\/]+)(\/(?<action>[^\/]+)(\/(?<path>.*))?)?/)

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
    when 'issues'
      if match[:path]
        get_issue match
      else
        get_issues match
      end
    end

  else

    get_repo match
  end
end

helpers do
  def get_commit match
    path = "/commits/#{match[:path]}"

    api_call match[:owner], match[:project], 'repos', path do |data|
      data = data['commit']

      reply_without_prefix match[:project] => "#{data['message'].lines.first} - by #{data['author']['name']} at #{Time.parse(data['author']['date']).to_s}"
    end
  end


  def get_file match
    branch, path = match[:path].split('/', 2)
    path = "/contents/#{path}"

    api_call match[:owner], match[:project], 'repos', path, ref: branch do |data|
      reply_without_prefix match[:project] => "#{data['name']}: #{data['size'].to_f.format_bytesize} #{data['type']}"
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

      result.gsub!(/[[:cntrl:]]/, '')

      reply_without_prefix "Line #{line}" => result
    end
  end


  def get_repo match
    api_call match[:owner], match[:project], 'repos' do |data|
      reply_without_prefix "#{match[:project]} (#{data['language']})" => "#{data['description']} - by #{data['owner']['login']}"
    end
  end


  def get_issues match
    api_call match[:owner], match[:project], 'repos', '/issues' do |data|
      issues = Hash.new 0

      data.each do |issue|
        $log.debug('github') { issue.inspect }

        issues[issue['state']] += 1
      end

      reply_without_prefix match[:project] => issues
    end
  end

  def get_issue match
    path = "/issues/#{match['path']}"

    api_call match[:owner], match[:project], 'repos', path do |data|
      reply_without_prefix "#{data['title']} (#{data['state']})" => {
        'Creator' => data['user']['login'],
        'Labels'  => data['labels'].map {|label| label['name']}.join(', '),
        'Created' => Time.parse(data['created_at']).to_s
      }
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
