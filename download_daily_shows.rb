#!/usr/bin/env ruby
require 'uri'
require 'net/http'
require 'nokogiri'
require 'date'

class Kickass
  def search_and_download(search_term)
    debug("\nSearch for: '#{search_term}'")
    page = nokogirize search_url(search_term)
    rows = page.css('table[class="data"] tr')
                .select { |tr| tr.text =~ /#{search_term}/i }
    debug("\t#{rows.count} torrent matches")

    if rows.count.zero?
      @zero_results_count && @zero_results_count += 1 # Hack, sorry
      return
    end

    # Download the first torrent listed with 720p
    hd_torrent = rows.find { |tr| tr.text =~ /720/ }
    add_torrent torrent_url_from_row(hd_torrent)

    # Download the first (most popular) torrent if there's no HD available
    add_torrent torrent_url_from_row(rows.first) if !hd_torrent
  end

  def get_last_week_shows(show_name, options = { only_720: false })
    date_range.each do |date|
      search_and_download "#{show_name} #{date.strftime('%Y %m %d')}".downcase
    end
  end

  def hack_to_get_this_season(show_name, season)
    @zero_results_count = 0

    (1..25).each do |n|
      break if @zero_results_count > 3
      episode = sprintf "%02d", n
      search_and_download "#{show_name} s#{season}e#{episode}"
    end
  end

  def date_range
    (Date.today - 6 .. Date.today).to_a.reverse
  end

  private

  def nokogirize(url)
    debug("Visit '#{url}'")
    response = Net::HTTP.get_response(URI.parse(url))
    Nokogiri::HTML(response.body)
  end

  def search_url(term)
    "https://kickass.to/usearch/#{URI.escape(term)}/"
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
  kickass.get_last_week_shows("daily show", only_720: true)
  #kickass.get_last_week_shows('nightly show', only_720: true)
  kickass.hack_to_get_this_season("last week tonight with john oliver", "02")
  kickass.hack_to_get_this_season("portlandia", "05")
end
