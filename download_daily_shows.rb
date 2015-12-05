#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'nokogiri'
require 'date'


class Kickass
  def initialize(options={})
    @last = options[:last] || 1  # Download up to <last> last episodes
    @max = options[:max] || 25  # Max episode number to search down from there
  end

  def get_by_date(show_name, options={})
    """Get last couple of episodes searching by date, from today"""

    @max = options[:max] if options[:max]
    @found_count = 0  # stops when it finds the last couple of episodes,
                      # doesn't keep searching down to the first one

    date_range.each do |date|
      break if @found_count >= @last
      search_and_download "#{show_name} #{date.strftime('%Y %m %d')}".downcase
    end
  end

  def get_by_season(show_name, season, options={})
    """Get last couple of episodes for a given season"""

    @max = options[:max] if options[:max]
    @found_count = 0  # stops when it finds the last couple of episodes,
                      # doesn't keep searching down to the first one

    ( 1 .. @max ).to_a.reverse.each do |n|
      break if @found_count >= @last
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
    debug("-> #{rows.count} torrent matches")
    return if rows.count.zero?


    # Download the first torrent listed with 720p
    hd_torrent = rows.find { |tr| tr.text =~ /720p/ }
    result = add_torrent torrent_url_from_row(hd_torrent)

    add_torrent(torrent_url_from_row(rows.first)) if result =~ /Error/

    @found_count += 1 if hd_torrent
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
    "https://kat.cr/usearch/#{URI.escape(term)}/"
  end

  def torrent_url_from_row(row)
    a = row && row.at_css('a[title="Torrent magnet link"]')
    a && a['href']
  end

  def add_torrent(url)
    return if url.nil? || url.empty?
    debug("Add torrent from: '#{url}'")
    result = `transmission-remote -a #{url}`
    debug("-> " + result)
    result
  end

  def debug(message)
    puts(message) if ENV['DEBUG']
  end
end


if __FILE__ == $PROGRAM_NAME
  kickass = Kickass.new(last: 1)
  # kickass.get_by_date("late show with stephen colbert")
  kickass.get_by_season("last week tonight with john oliver", "02", max: 45)
  # kickass.get_by_season("louie", "05", max: 13)


  # old
  # kickass.get_by_date("daily show")
  # kickass.get_by_season("game of thrones", "05", max: 10)
  # kickass = Kickass.new(last: 35)
  # kickass.get_by_season("adventure time", "05", max: 20)
  # kickass.get_by_season("key and peele", "05", max: 13)
  # kickass = Kickass.new(last: 11)
  # kickass.get_by_season("key and peele", "04", max: 13)
end
