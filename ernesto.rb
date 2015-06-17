#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'flickraw'
require 'uri'
require 'open-uri'

module Ernesto
  class Helpers
    def anagram(params)
      query = params[:text].sub(/^#{params[:trigger_word]}\w*/,'').strip
      query_string = "source_text=#{URI.encode(query)}&seen=true&submitbutton=Generate%20Anagrams"
      resp = open("http://www.anagramgenius.com/server.php?#{query_string}").read
      result = resp.scan(%r{anagrams to.+<span class="black-18">\s*'(.+?)'\s*</span>}).flatten.first
      { text: %{"#{query}" ~> "#{result}"} }
    end

    def flickr(params)
      consolation_prizes = [
        'taco. :taco:',
        'drink. :cocktail:',
        '<http://i.imgur.com/Ijz3Uwg.gif|monkey washing a cat>',
        'whole bunch of nothing.'
      ]
      api = FlickRaw::Flickr.new
      query = params[:text].sub(/^#{params[:trigger_word]}\w*/,'')
      list = api.photos.search text: query, privacy_filter: 1, per_page: 30
      sample = list.to_a.compact.sample
      return "No results found. But here's a #{consolation_prizes.sample}" if sample.nil?

      info = api.photos.getInfo(photo_id: sample.id)
      sizes = api.photos.getSizes(photo_id: sample.id)
      url = sizes.to_a.reverse.find { |s| s['label'] !~ /Original/i }['source']
      result = { text: "<#{url}|#{info.title}>" }
      if params[:debug]
        result['sizes'] = sizes.to_a.collect { |s| s.to_hash }
      end
      result
    end
    
    def eightball(params)
      resp = (1..32).to_a.sample
      query = params[:text].sub(/^#{params[:trigger_word]}\W+/,'')
      user = params[:user_name]
      cacheBuster = rand(10000)
      img = params[:trigger_word] =~ /^[Ee]nable/ ? 'http://i.imgur.com/NySLl3v.jpg' : "http://toastbucket.com/balls/#{resp}.gif"
      { text: "<#{img}?#{cacheBuster}|#{user}: “#{query}”>" }
    end

    def trying(params)
      user = params[:user_name]
      "Try harder, #{user}"
    end

    def roll(params)
      request = params[:text].split(/\s+/).last
      (count,die) = request.split(/[dD]/).collect(&:to_i)
      if count > 1000
        "Fuck you and your big numbers."
      else
        (1..count).collect { rand(1..die.to_i) }.join(", ")
      end
    end
  end

  class Application < Sinatra::Base
    configure do
      FlickRaw.api_key = ENV['flickr_api_key']
      FlickRaw.shared_secret = ENV['flickr_shared_secret']
      set :hooks, {
        flickr: /flickr/,
        trying: /trying/,
        eightball: /(^8-?[Bb]all)|(enable)r/,
        roll: /roll/,
        anagram: /^ana(gram)?/
      }
    end

    post '/webhook' do
      trigger = params[:trigger_word].strip.downcase
      helper  = settings.hooks.find { |m,re| trigger =~ re }.first
      content_type 'application/json'
      response = Helpers.new.send(helper, params)
      case response
      when Hash then response.to_json
      when String then { 'text' => response }.to_json
      end
    end
  end
end
