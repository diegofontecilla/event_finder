require 'nokogiri'
require 'open-uri'
require 'httparty'
require 'byebug'

class Scraper
  attr_reader :event_dom

  def parser(url)
    unparsed_url = HTTParty.get(url)
    parsed_url = Nokogiri::HTML(unparsed_url)
  end

  def scrape(url)
    index = 0
    parsed_url = parser(url)

    while index < 10
      @event_dom = Nokogiri::HTML(open(ticket_info_button(parsed_url, index)))
      printer
      index += 1
    end
  end

  def ticket_info_button(parsed_url, index)
    parsed_url.css('#Content > [class="content block-group"] >
    [class="content block-group chatterbox-margin"] >
    [class="block diptych text-right"] > a')[index]["href"]
  end

  def go_to_next_page
    url = next_page_button
    scrape(url)
  end

  def next_page_button
    parsed_url = parser(url)
    parsed_url.css('#Content > [class="content block-group"] >
    [class="content block"] > [class="block-group advance-filled section-margins padded text-center"] >
    a')[0]["href"]
  end

  def base_css_query(event_dom)
    event_dom.css('#Content > [class="content"] >
    [class="block-group"] > [class="left block"] >
    [class="left full-width-mobile event-information event-width"]')
  end

  def artist(event_dom)
    base_css_query(event_dom).css('h1').text
  end

  def venue_details(arg)
    venue_details = base_css_query(event_dom).css('[class="venue-details"] > h2')
    return venue_details.text.split(":")[0] if arg == "c"
    return venue_details.text.split(":")[1].strip! if arg == "v"
  end

  def get_date(event_dom)
    base_css_query(event_dom).css('[class="venue-details"] > h4').text
  end

  def price(event_dom)
    event_dom.css('#Content > [class="content"] >
    [class="block-group block-group-flex"] > form >
    [class="BuyBox block"] > table > tbody > tr >
    [class="half text-top text-right"] > p').text
  end

  def printer
    p "Artist: #{artist(event_dom)}"
    p "City: #{venue_details("c")}"
    p "Venue: #{venue_details("v")}"
    p "Date: #{get_date(event_dom)}"
    p "Price: #{price(event_dom)}"
    p '------------------'
  end
end


scraper = Scraper.new
# p scraper.scrape("https://www.wegottickets.com/searchresults/all")
p scraper.go_to_next_page
