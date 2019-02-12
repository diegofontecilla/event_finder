require 'nokogiri'
require 'open-uri'
require 'httparty'
require 'byebug'

class Scraper
  attr_reader :event_dom, :url

  def initialize(url)
    @url = url
  end

  def parser(url)
    unparsed_url = HTTParty.get(url)
    parsed_url = Nokogiri::HTML(unparsed_url)
  end

  def scrape
    index = 0
    parsed_url = parser(url)

    while index < 10
      @event_dom = Nokogiri::HTML(open(ticket_info_button(parsed_url, index)))
      printer
      index += 1
    end

    go_to_next_page
  end

  def ticket_info_button(parsed_url, index)
    parsed_url.css('#Content > [class="content block-group"] >
    [class="content block-group chatterbox-margin"] >
    [class="block diptych text-right"] > a')[index]["href"]
  end

  def go_to_next_page
    set_new_url
    scrape
  end

  def set_new_url
    unparsed_url = HTTParty.get(url)
    parsed_url = Nokogiri::HTML(unparsed_url)

    @url = get_new_url(parsed_url)
  end

  def get_new_url(parsed_url)
    parsed_url.css('#Content > [class="content block-group"] >
    [class="content block"] > [class="block-group advance-filled section-margins padded text-center"] >
    a')[0]["href"]
  end

  def base_css_query(event_dom)
    event_dom.css('#Content > [class="content"] >
    [class="block-group"] > [class="left block"] >
    [class="left full-width-mobile event-information event-width"]')
  end

  def artist
    base_css_query(event_dom).css('h1').text
  end

  def venue_details(arg)
    venue_details = base_css_query(event_dom).css('[class="venue-details"] > h2')
    return venue_details.text.split(":")[0] if arg == "get city"
    return venue_details.text.split(":")[1].strip! if arg == "get venue"
  end

  def get_date
    base_css_query(event_dom).css('[class="venue-details"] > h4').text
  end

  def price
    event_dom.css('#Content > [class="content"] >
    [class="block-group block-group-flex"] > form >
    [class="BuyBox block"] > table > tbody > tr >
    [class="half text-top text-right"] > p').text
  end

  def printer
    puts "Artist: #{artist}"
    puts "City: #{venue_details("get city")}"
    puts "Venue: #{venue_details("get venue")}"
    puts "Date: #{get_date}"
    puts "Price: #{price}"
    puts '----------------------------------'
  end
end


scraper = Scraper.new("https://www.wegottickets.com/searchresults/all")
p scraper.scrape
