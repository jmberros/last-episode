#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'nokogiri'
require 'date'


class Kickass
  def initialize
    @max = 3  # Download up to the three last episodes
  end

  def get_by_date(show_name)
    """Get last couple of episodes searching by date, from today"""

    @found_count = 0  # stops when it finds the last couple of episodes,
                      # doesn't keep searching down to the first one

    date_range.each do |date|
      break if @found_count >= @max
      search_and_download "#{show_name} #{date.strftime('%Y %m %d')}".downcase
    end
  end

  def get_by_season(show_name, season)
    """Get last couple of episodes for a given season"""

    @found_count = 0  # stops when it finds the last couple of episodes,
                      # doesn't keep searching down to the first one

    ( 1 .. 15 ).to_a.reverse.each do |n|  # 25 is just a plausible max
      break if @found_count >= @max
      episode = sprintf "%02d", n
      search_and_download "#{show_name} s#{season}e#{episode}"
    end
  end

  private

  def date_range
    (Date.today - 6 .. Date.today).to_a.reverse
  end

  def search_and_download(search_term)
    debug("\nSearch for: '#{search_term}'")
    page = nokogirize search_url(search_term)
    rows = page.css('table[class="data"] tr')
                .select { |tr| tr.text =~ /#{search_term}/i }
    debug("\t#{rows.count} torrent matches")
    return if rows.count.zero?


    # Download the first torrent listed with 720p
    hd_torrent = rows.find { |tr| tr.text =~ /720p/ }
    add_torrent torrent_url_from_row(hd_torrent)
    @found_count += 1 if hd_torrent
    debug("Found #{@found_count} so far")

    # Download the first (most popular) torrent if there's no HD available
    #add_torrent torrent_url_from_row(rows.first) if !hd_torrent
  end

  def nokogirize(url)
    debug("Visit '#{url}'")
    begin
      response = Net::HTTP.get_response(URI.parse(url))
      if response.code == '301'
        response = Net::HTTP.get_response(URI.parse(response.header['location']))
      end
      Nokogiri::HTML(response.body)
    rescue SocketError, Errno::ETIMEDOUT
      exit # Exit silently if there's laggy or no internet
    end
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
    puts(message) if ENV['DEBUG']
  end
end


if __FILE__ == $PROGRAM_NAME
  kickass = Kickass.new
  kickass.get_by_date("daily show")
  kickass.get_by_season("last week tonight with john oliver", "02")
  kickass.get_by_season("game of thrones", "05")
  kickass.get_by_season("louie", "05")
end
