#!/usr/bin/env ruby

require "open-uri"
require "pony"

def mail_IP
  return if current_IP_already_sent?

  Pony.mail(
    subject: "#{hostname} IP - #{Time.now}",
    from: "Juan Bot",
    to: destination_addresses,
    html_body: "#{current_IP}",
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

  File.open(logfile, 'w') { |f| f.write(current_IP + "\n") }
end

def smtp_credentials
  YAML::load_file File.expand_path "~/.smtp_credentials.yml"
end

def hostname
  `hostname`.strip
end

def destination_addresses
  raise "Please define TO=<destination_address>" unless ENV["TO"]
  ENV["TO"].split(",")
end

def logfile
  File.expand_path("~/.last_sent_ip")
end

def current_IP
  $current_IP ||= open("http://icanhazip.com/s").read.strip
end

def last_sent_IP
  File.read(logfile).strip if File.exists?(logfile)
end

def current_IP_already_sent?
  last_sent_IP == current_IP
end

def main
  mail_IP unless current_IP_already_sent?
end

main if __FILE__ == $0
