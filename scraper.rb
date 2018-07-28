#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    members_table.xpath('.//tr[td]').map do |tr|
      data = fragment(tr => MemberRow).to_h
      data[:party_id] = parties.find { |p| p[:shortname] == data[:party] }[:id] rescue ''
      data
    end
  end

  field :parties do
    party_table.xpath('.//tr[td[a]]').map { |tr| fragment(tr => PartyRow).to_h }
  end

  private

  def members_table
    noko.xpath('//table[.//th[contains(.,"Bemerkung")]]')
  end

  def party_table
    noko.xpath('//table[.//th[contains(.,"Partei")]]')
  end
end

class MemberRow < Scraped::HTML
  field :name do
    tds[0].css('a').map(&:text).map(&:tidy).first
  end

  field :id do
    tds[0].css('a/@wikidata').map(&:text).first
  end

  field :party do
    tds[1].text.tidy
  end

  field :area do
    tds[2].text.tidy
  end

  private

  def tds
    noko.css('td')
  end
end


class PartyRow < Scraped::HTML
  field :name do
    td.css('a').map(&:text).map(&:tidy).first
  end

  field :id do
    td.css('a/@wikidata').map(&:text).first
  end

  field :shortname do
    td.text[/\((.*?)\)/, 1]
  end

  private

  def td
    noko.css('td').first
  end
end

url = 'https://de.wikipedia.org/wiki/Liste_der_Mitglieder_des_liechtensteinischen_Landtags_(2017)'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party])
