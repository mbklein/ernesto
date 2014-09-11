#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'flickraw'

module Ernesto
  class Helpers
    def flickr(params)
      consolation_prizes = [
        'taco. :taco:',
        'drink. :cocktail:',
        '<http://i.imgur.com/Ijz3Uwg.gif|monkey washing a cat>',
        'whole bunch of nothing.'
      ]
      api = FlickRaw::Flickr.new
      query = params[:text].sub(/^#{params[:trigger_word]}\s*/,'')
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

    def

    def eightball(params)
      resp = (1..32).to_a.sample
      { text: "<http://toastbucket.com/balls/31.gif|>" }
    end

    def trying(params)
      user = params[:user_name]
      "Try harder, #{user}"
    end
  end

  class Application < Sinatra::Base
    configure do
      FlickRaw.api_key = ENV['flickr_api_key']
      FlickRaw.shared_secret = ENV['flickr_shared_secret']
      set :hooks, {
        flickr: /flickr/,
        trying: /trying/,
        eightball: /^8-?[Bb]all/
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
