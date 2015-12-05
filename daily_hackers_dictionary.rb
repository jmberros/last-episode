#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-

require 'uri'
require 'net/http'
require 'nokogiri'
require 'date'
require 'pony'
# require 'pry-debugger'

def debug(message)
  puts(message)
end

def base_url
  "http://www.catb.org/jargon/html/"
end

def nokogirize(url)
  debug("Visit '#{url}'")
  response = Net::HTTP.get_response(URI.parse(url))
  Nokogiri::HTML(response.body)
end

def get_todays_term
  index_page = nokogirize(base_url + "go01.html")
  links = index_page.css("dl dd dl dt a")
  n = todays_lucky_number(links.count)
  definition_url = base_url + links[n]["href"]

  def_page = nokogirize(definition_url)
  term = def_page.css("dt b").text
  pronunciation = def_page.css("span.pronunciation").map(&:text).join(", ")
  definition = def_page.css("dd").map(&:text).join("<br><br>").gsub("   ", " ")

  Pony.mail(
    subject: "Hacker's dictionary: \"#{term}\"",
    from: "'JuanBOT' <juanbot@beleriand>",
    to: ["'The Juanma' <juanmaberros@gmail.com>", "'Peluca' <arami035@gmail.com>"],
    html_body: \
      "<b>#{term}</b>: #{pronunciation}<br><br>"\
      "#{definition}",
    via: :smtp,
    via_options: {
      address: 'smtp.gmail.com',
      port: '587',
      enable_starttls_auto: true,
      user_name: smtp_credentials["user"],
      password: smtp_credentials["pass"],
      authentication: :plain,
      domain: "localhost.localdomain"
    }
  )
end

def todays_lucky_number(total)
  today = (Date.today - Date.new(1970, 1, 1)).to_i # A unique number for each day
  (today % total) - ARGV.first.to_i # A number in [0 .. total) for today
end

def smtp_credentials
  YAML::load_file File.expand_path("~/.smtp_credentials")
end


get_todays_term if __FILE__ == $PROGRAM_NAME
