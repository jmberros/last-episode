#!/usr/bin/env ruby
# encoding: utf-8

require "open-uri"
require "nokogiri"
require "fileutils"
require "pony"
require "erb"
require "action_view"
require "active_support/all"

include ActionView::Helpers::NumberHelper


def smtp_credentials
  filepath = File.expand_path "~/.smtp_credentials"
  raise "Credentials file '#{filepath}' doesn't exist" unless File.exists? filepath
  YAML::load_file File.expand_path filepath
end

def addressees
  lucky_ones = {
    Juangui: "juanmaberros@gmail.com",
    Amychica: "arami035@gmail.com",
    Jesolandia: "jesica.berros@gmail.com",
  }

  if ENV["DEBUG"]
    lucky_ones = lucky_ones[0..0]
  end

  lucky_ones.map{ |name, address| "'#{name}' <#{address}>" }
end

def already_sent_today?(write=false)
  filename = File.join Dir.home, ".calvin_cron_last_date_sent"

  if write
    File.write(filename, Date.today)
  end

  Date.today == Date.parse( File.read(filename) ) if File.exists? filename
end

def first_strip_date
  Date.parse "1985/11/18"
end

def today_strip_date
  # when_to_send_first_strip = Date.parse "2016/01/04"
  # Date.today - (when_to_send_first_strip - first_strip_date)

  # Best so the current date is syncronized with the comic date,
  # though you'll lose the 29th feb comics since 30 % 4 != 0
  30.years.ago.to_date
end

def strip_number
  strip_number = (today_strip_date - first_strip_date).to_i + 1
  number_with_delimiter strip_number
end

def url
  "http://www.gocomics.com/calvinandhobbes/" +
  "#{today_strip_date.strftime "%Y/%m/%d" }"
end

def img_url
  doc = Nokogiri::HTML open url
  doc.css(".feature img").last["src"]
end

def debug(msg)
  puts msg if ENV['DEBUG']
end

def download
  target_dir = File.join Dir.home, "Dropbox", "calvin_strips",
                         today_strip_date.year.to_s
  FileUtils.mkdir_p target_dir
  filename = today_strip_date.strftime("%F_%A_N#{strip_number}.gif").downcase
  fullpath = File.join target_dir, filename

  debug("download URL: '#{img_url}'")
  debug("target path: '#{fullpath}'")

  `wget -qO #{fullpath} #{img_url}`
end

def mail_it
  template_path = File.join File.dirname(__FILE__), "mail_calvin.erb"
  mail_template = File.read template_path

  debug("address: #{addressees}")
  Pony.mail(
    subject: "Calvin & Hobbes · #{today_strip_date.strftime "%d %b, %Y · %A" }",
    from: "'Juanbot' <juanbot@#{`hostname`.chomp}>",
    to: addressees.first,
    bcc: ENV["DEBUG"] ? nil : addressees,
    html_body: ERB.new(mail_template).result,
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
end


exit if already_sent_today?
download
mail_it and already_sent_today?(write=true)
