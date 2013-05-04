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


# TODO: https://developers.google.com/custom-search/v1/overview
#       http://googlecode.blogspot.com/2010/11/introducing-google-apis-console-and-our.html


require "uri"
require "net/http"
require 'multi_json'

register 'Search the Internet with Google.'


command 'g', 'Search for web pages using Google.' do
  argc! 1

  get_result(@params[0], :web) {|r| reply r}
end

command 'gimage', 'Search for images using Google.' do
  argc! 1

  get_result(@params[0], :images) {|r| reply r}
end

command 'gvideo', 'Search for videos using Google.' do
  argc! 1

  get_result(@params[0], :video) {|r| reply r}
end

command 'gpatent', 'Search patents using Google.' do
  argc! 1

  get_result(@params[0], :patent) {|r| reply r}
end

command 'gbook', 'Search books using Google.' do
  argc! 1

  get_result(@params[0], :books) {|r| reply r}
end

command 'gnews', 'Search news using Google.' do
  argc! 1

  get_result(@params[0], :news) {|r| reply r}
end

command 'gblog', 'Search blogs using Google.' do
  argc! 1

  get_result(@params[0], :blogs) {|r| reply r}
end

helpers do
  def get_result query, type
    $log.debug('google') { "Searching #{type} for #{query}" }

    uri = URI("https://ajax.googleapis.com/ajax/services/search/#{type}")
    query_hash = {:v => "1.0", :q => query}

    http_get(uri, query_hash) do |http|

      response = MultiJson.load http.response

      results = []
      limit = get_config(:resultlimit, 3).to_i

      response["responseData"]["results"].each_with_index do |result, num|

        break if num >= limit

        case type

        when :web
          results << "\02#{html_decode result["titleNoFormatting"]}\02 - #{URI.unescape(result["url"])}"

        when :images
          results << "\02#{html_decode result["titleNoFormatting"]}\02 - #{URI.unescape(result["url"])}"

        when :books
          results << "\02#{html_decode result["titleNoFormatting"]}\02 by #{html_decode result["authors"]} - #{URI.unescape(result["url"])} - #{result["bookId"]} - Published: #{result["publishedYear"]} - #{result["pageCount"]} Pages"

        when :news
          results << "\02#{html_decode result["titleNoFormatting"]}\02 - #{URI.unescape(result["url"])}"

        when :blogs
          results << "\02#{html_decode result["titleNoFormatting"]}\02 by #{html_decode result["author"]} - #{URI.unescape(result["postUrl"])} - Published #{result["publishedDate"]}"

        when :patent
          results << "\02#{html_decode result["titleNoFormatting"]}\02 - #{URI.unescape(result["url"])} - assigned to #{html_decode result["assignee"]} - #{result["patentNumber"]} (#{result["patentStatus"]}) - Applied for on: #{result["applicationDate"]}"

        when :video
          results << "\02#{html_decode result["titleNoFormatting"]}\02 - #{result["url"]}"

        end

      end

      yield (results.empty? ? "No results." : results)
    end
  end

end
# vim: set tabstop=2 expandtab:
