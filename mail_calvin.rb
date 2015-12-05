#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'pony'
require 'colorize'

def smtp_credentials
  YAML::load_file File.expand_path("~/.smtp_credentials")
end

url = "http://www.gocomics.com/calvinandhobbes"
doc = Nokogiri::HTML(open(url))
img_url = doc.css("img[alt='Calvin and Hobbes']").first['src']

target_dir = "#{Dir.home}/Dropbox/calvin_strips"
filename = Date.today.strftime('%F_%A').downcase
fullpath = "#{target_dir}/#{filename}.gif"

FileUtils.mkdir(target_dir) unless File.directory? target_dir
`wget -O #{fullpath} #{img_url}`

Pony.mail(
  subject: "Calvin Strip ~ #{Date.today.strftime('%A %F')} ",
  from: "'JuanBOT' <juanbot@beleriand>",
  to: ["'The Juanma' <juanmaberros@gmail.com>", "'Peluca' <arami035@gmail.com>"],
  html_body: "<img src='#{img_url}' style='width: 80%;'>",
  via: :smtp,
  via_options: {
    address: 'smtp.gmail.com',
    port: '587',
    user_name: smtp_credentials["user"],
    password: smtp_credentials["pass"],
    enable_starttls_auto: true,
    authentication: :plain,
    domain: "localhost.localdomain"
  }
)
