#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'flickraw'

module Ernesto
  class Helpers
    def flickr(params)
      api = FlickRaw::Flickr.new
      query = params[:text].sub(/^#{params[:trigger_word]}\s*/,'')
      list = api.photos.search text: query, privacy_filter: 1, per_page: 30
      info = api.photos.getInfo(photo_id: list.to_a.sample.id)
      sizes = api.photos.getSizes(photo_id: info.id)
      url = sizes.to_a.reverse.find { |s| s['label'] !~ /Original/i }['source']
      result = { text: "#{info.title}\n#{url}" }
      if params[:debug]
        result['sizes'] = sizes.to_a.collect { |s| s.to_hash }
      end
      result
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
        trying: /trying/
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
