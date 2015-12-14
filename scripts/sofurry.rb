#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

need_module! 'url_handler', 'http'

register 'Fetch information from SoFurry.'

url(/\/\/((www|wiki)\.)?sofurry\.com\/view\/[0-9]+/) do
  $log.info('sofurry.url') { @uri.inspect }

  match = @uri.to_s.match(/\/view\/(?<id>[0-9]+)(#(?<comment_id>[0-9]+)?)?$/)

  if match[:comment_id]
    get_comment match
  else
    get_submission match
  end
end

url(/\/\/((?!(www|wiki)\.).+)\.sofurry\.com\/?$/) do
  match = @uri.to_s.match(/\/\/(?<user_name>(?!(www|wiki)\.).+)\.sofurry\.com\/?$/)

  get_profile match
end

helpers do

  def get_profile match
    api = URI('http://api2.sofurry.com/std/getUserProfile')

    args = {
      'username' => match[:user_name],
      'format' => 'json'
    }

    json_get api, args, true do |json|
      data, country, city = {}, '', ''

      # yeah, a loop is kind of a fucko way to do this,
      # but the code is easier to read/write --Kabaka
      json.each do |key, value|
        unless !!value == value
          next if value.nil? or value.empty? or value == '0'
        end

        case key

        when 'species'
          data['Species'] = value

        when 'gender'
          case value
          when '1'
            data['Gender'] = 'Male'
          when '2'
            data['Gender'] = 'Female'
          when '3'
            data['Gender'] = 'Herm'
          end

        when 'orientation'
          case value
          when '1'
            data['Orientation'] = 'Heterosexual'
          when '2'
            data['Orientation'] = 'Homosexual'
          when '3'
            data['Orientation'] = 'Bisexual'
          when '4'
            data['Orientation'] = 'Omnisexual'
          end

        when 'mateshipStatus'
          case value
          when '1'
            data['Mateship Status'] = 'Single, Uninterested'
          when '2'
            data['Mateship Status'] = 'Single, Seeking Casual'
          when '3'
            data['Mateship Status'] = 'Single, Seeking Permanent'
          when '4'
            data['Mateship Status'] = 'Mated, Open'
          when '5'
            data['Mateship Status'] = 'Mated, Closed'
          end

        when 'description'
          data['Description'] = value unless value.empty?

        when 'submissionCount'
          data['Submissions']       = value
        when 'submissionViewCount'
          data['Submission Views']  = value
        when 'commentCount'
          data['Comments Received'] = value

        when 'commentPostedCount'
          data['Comments Posted']   = value

        when 'country'
          country = value
        when 'city'
          city = value

        when 'registrationDate'
          data['Registered'] = DateTime.parse(value).strftime('%F')
        end
      end

      if not country.empty? and not city.empty?
        data['Location'] = "#{city}, #{country}"
      elsif not country.empty?
        data['Location'] = country
      elsif not city.empty?
        data['Location'] = city
      end

      reply_without_prefix json['username'] => data
    end
  end

  def get_comment match
    api = URI('http://api2.sofurry.com/api/getComments')

    args = {
      :id => match[:id],
      'format' => 'json'
    }

    json_get api, args, true do |json|
      comment = json['data']['entries'].select {|c| c['id'] == match[:comment_id]}.first

      next unless comment

      reply_without_prefix comment['username'] =>
        "#{html_decode clean_result comment['message']}"
    end
  end

  def get_submission match
    api = URI('http://api2.sofurry.com/std/getSubmissionDetails')

    args = {
      :id => match[:id],
      'format' => 'json'
    }

    json_get api, args, true do |json|
      case json['contentType']
      when '0'
        type = 'Story'
      when '1'
        type = "Art (#{json['width']}x#{json['height']} #{json['fileExtension']})"
      when '2'
        type = 'Music'
      when '3'
        type = 'Journal'
      when '4'
        type = "Photo (#{json['width']}x#{json['height']} #{json['fileExtension']})"
      else
        type = 'Unknown Type'
      end

      reply_without_prefix type =>
        "#{json['title']} - #{html_decode clean_result json['description']}"
    end
  end
end

# vim: set tabstop=2 expandtab:
