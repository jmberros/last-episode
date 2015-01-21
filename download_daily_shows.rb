#!/usr/bin/env ruby
require 'uri'
require 'net/http'
require 'nokogiri'
require 'date'

class Kickass
  def get_last_weeks_shows(show_name, options = { only_720: false })
    date_range.each do |date|
      search_term = "#{show_name} #{date.strftime('%Y %m %d')}".downcase
      debug("\n#{date.strftime('%A %D')} ~ Search for: '#{search_term}'")

      page = nokogirize search_url(search_term)
      rows = page.css('table[class="data"] tr')
                 .select { |tr| tr.text =~ /#{search_term}/i }
      debug("\t#{rows.count} torrent matches")
      next if rows.count.zero?

      # Download the first (most popular) torrent
      add_torrent torrent_url_from_row(rows.first) unless options[:only_720]

      # Download the first torrent listed with 720p
      add_torrent torrent_url_from_row(rows.find { |tr| tr.text =~ /720/ })
    end
  end

  def date_range
    (Date.today - 14 .. Date.today).to_a.reverse
  end

  private

  def nokogirize(url)
    debug("Visit '#{url}'")
    response = Net::HTTP.get_response(URI.parse(url))
    Nokogiri::HTML(response.body)
  end

  def search_url(term)
    "https://kickass.so/usearch/#{URI.escape(term)}/"
  end

  def torrent_url_from_row(row)
    a = row && row.at_css('a[title="Download torrent file"]')
    a && a['href']
  end

  def add_torrent(url)
    return if url.nil? || url.empty?
    debug("\tAdd torrent from: '#{url}'")
    result = `transmission-remote -a #{url}`
    debug("\t-> " + result)
  end

  def debug(message)
    puts(message)
  end
end


if __FILE__ == $PROGRAM_NAME
  kickass = Kickass.new
  kickass.get_last_weeks_shows('nightly show')
  kickass.get_last_weeks_shows('daily show', only_720: true)
end
