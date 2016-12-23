#!/usr/bin/env ruby

require "open-uri"
require "yaml"
require "nokogiri"
require "fileutils"
require "pony"
require "erb"
require "action_view"
require "active_support/all"

include ActionView::Helpers::NumberHelper


class ComicDownloader
  def target_dir
    File.expand_path "~/Dropbox/calvin_strips/#{today_strip_date.year}"
  end

  def today_strip_number
    first_strip_date = Date.parse "1985/11/18"
    strip_number = (today_strip_date - first_strip_date).to_i + 1
    number_with_delimiter strip_number
  end

  def target_filename
    today_strip_date.strftime("%F_%A_N#{today_strip_number}.gif").downcase
  end

  def today_strip_date
    # First strip was in 1985/11/18
    # This cycle was initiated in 2015/11/18
    30.years.ago.to_date
  end

  def today_comic_url
    date_stub = today_strip_date.strftime "%Y/%m/%d" 
    "http://www.gocomics.com/calvinandhobbes/#{date_stub}"
  end

  def today_img_url
    @img_url ||= begin
      doc = Nokogiri::HTML open today_comic_url
      doc.css(".feature img").last["src"]
    end
  end

  def download_today_strip
    FileUtils.mkdir_p target_dir
    `wget -qO #{File.join(target_dir, target_filename)} #{today_img_url}`
  end
end

class ComicMailer
  def initialize
    @smtp_creds_file = File.expand_path "~/.smtp_credentials.yml"
    @addressees_file = File.expand_path "~/.mail_calvin_targets.yml"
    @sent_logfile = File.expand_path "~/.calvin_cron_last_date_sent"

    @comic_downloader = ComicDownloader.new
  end 

  def smtp_credentials
    YAML::load_file @smtp_creds_file
  end

  def addressees
    targets = YAML::load_file @addressees_file
    targets.map{ |name, address| "'#{name}' <#{address}>" }
  end

  def already_sent_today?
    Date.today == Date.parse(File.read(@sent_logfile))
  end

  def download_and_mail
    @comic_downloader.download_today_strip

    template_path = File.join(File.dirname(__FILE__), "mail_calvin.erb")
    mail_template = File.read template_path

    # Data for the mail template
    date_str = @comic_downloader.today_strip_date.strftime("%d %b, %Y")
    img_url = @comic_downloader.today_img_url
    comic_url = @comic_downloader.today_comic_url
    strip_number = @comic_downloader.today_strip_number

    Pony.mail(
      subject: "Calvin & Hobbes · #{date_str}",
      from: "'C&H Bot' <calvin-and-hobbes-bot@#{`hostname`.chomp}>",
      to: addressees.first,
      bcc: addressees[1..-1],
      html_body: ERB.new(mail_template).result(binding),
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

  def log_send_event
    File.write(@sent_logfile, Date.today)
  end
end

# FIXME: deal with 29th Feb!

def main
  comic_mailer = ComicMailer.new

  unless comic_mailer.already_sent_today?
    comic_mailer.download_and_mail
    comic_mailer.log_send_event
  end
end

main if __FILE__ == $0

