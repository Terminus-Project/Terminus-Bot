# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco,
# Marshall Fowler (http://terminus-bot.net/)
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


require 'multi_json'

need_module! 'http'

register 'Display the first few lines of the OP in a linked 4chan thread.'

url /(.+boards\.)4chan\.org\/([a-z0-9]+)\/res\/([1-9][0-9]+)/ do
  $log.info('4chan.url') { @uri.inspect }
  get_thread_title @uri.path 
end

helpers do
  def get_thread_title path
    api = URI("https://api.4chan.org#{path}.json")

    http_get(api, {}, false) do |http|
      if http.response.empty?
        reply "\002404\02 - Thread not found."
        next 
      end


      data = MultiJson.load http.response

      reply "Thread \02#{data["posts"][0]['no']}\02: #{html_decode clean_result data["posts"][0]['com']}"
    end
  end
end

# vim: set tabstop=2 expandtab
