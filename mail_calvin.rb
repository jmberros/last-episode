#!/usr/bin/env ruby

require "open-uri"
require "nokogiri"
require "fileutils"
require "pony"
require "erb"
require "action_view"

include ActionView::Helpers::NumberHelper


def smtp_credentials
  YAML::load_file File.expand_path("~/.smtp_credentials")
end

def addressees
  lucky_ones = {
    Juangui: "juanmaberros@gmail.com",
    Amychica: "arami035@gmail.com",
    Jesolandia: "jesica.berros@gmail.com",
  }

  lucky_ones.map{ |name, address| "'#{name}' <#{address}>" }
end

first_strip_date = Date.parse("1985/11/18")
when_to_send_first_strip = Date.parse("2016/01/04")
today_strip_date = Date.today - (when_to_send_first_strip - first_strip_date)
strip_number = (today_strip_date - first_strip_date).to_i + 1
strip_number = number_with_delimiter(strip_number)

url = "http://www.gocomics.com/calvinandhobbes/" +
      "#{today_strip_date.strftime("%Y/%m/%d")}"
doc = Nokogiri::HTML open(url)
img_url = doc.css(".feature img").last["src"]

target_dir = File.join(Dir.home, "Dropbox", "calvin_strips",
                       today_strip_date.year.to_s)
FileUtils.mkdir_p(target_dir)
filename = today_strip_date.strftime("%F_%A_N#{strip_number}.gif").downcase
fullpath = File.join(target_dir, filename)

`wget -O #{fullpath} #{img_url}`

mail_template = File.read("./mail_calvin.erb")

Pony.mail(
  subject: "Calvin & Hobbes · #{today_strip_date.strftime("%d %b, %Y · %A")}",
  from: "'Juanbot' <juanbot@beleriand>",
  to: addressees.shift,
  bcc: addressees,
  html_body: ERB.new(mail_template).result(),
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
