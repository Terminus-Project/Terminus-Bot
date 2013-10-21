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

need_module! 'http'

require 'rexml/document'

register 'Look up Domino\'s order status.'

# TODO: add automatic tracking and update announcement

command 'dominos', 'Look up the status for the Domino\'s order associated with the given phone number.' do
  argc! 1

  # just strip all non-digit input in case someone used weird formatting
  phone = @params.first.delete '^0-9'

  unless phone.length == 10
    raise 'Invalid phone number. Please enter ten digits.'
  end

  url = URI('http://trkweb.dominos.com/orderstorage/GetTrackerData')

  opt = {:Phone => phone}

  http_get(url, opt) do |http|
    begin
      status = REXML::Document.new(http.response).elements['//GetTrackerDataResponse/OrderStatuses/OrderStatus']
    rescue
      raise 'Order not found.'
    end

    unless status
      raise 'Order not found.'
    end

    status_text = status.elements['OrderStatus'].text
    status_time = status.elements['AsOfTime'].text
    status_time = DateTime.parse(status_time).to_time.strftime('%F %r')

    reply "#{status_text} as of #{status_time} (store time)"
  end
end


# vim: set tabstop=2 expandtab:
