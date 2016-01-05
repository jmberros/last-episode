#!/usr/bin/env ruby

require "open-uri"
require "nokogiri"
require "fileutils"
require "pony"


def smtp_credentials
  YAML::load_file File.expand_path("~/.smtp_credentials")
end

thirty_years_ago = Date.today - 11004
url = "http://www.gocomics.com/calvinandhobbes/" + 
      "#{thirty_years_ago.strftime("%Y/%m/%d")}"
doc = Nokogiri::HTML open(url)
img_url = doc.css(".feature img").last["src"]

target_dir = File.join(Dir.home, "Dropbox", "calvin_strips",
                       thirty_years_ago.year.to_s)
FileUtils.mkdir_p(target_dir)
filename = thirty_years_ago.strftime("%F_%A.gif").downcase
fullpath = File.join(target_dir, filename)

`wget -O #{fullpath} #{img_url}`

Pony.mail(
  subject: "Calvin & Hobbes · #{thirty_years_ago.strftime("%d %b, %Y · %A")}",
  from: "'JuanBOT' <juanbot@beleriand>",
  to: ["'The Juanma' <juanmaberros@gmail.com>", "'Peluca' <arami035@gmail.com>"],
  html_body: "<img src='#{img_url}' style='width: 100%;'>",
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
