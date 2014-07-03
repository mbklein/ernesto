#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'flickraw'

class FlickrHook < Sinatra::Base
  configure do
    FlickRaw.api_key = ENV['flickr_api_key']
    FlickRaw.shared_secret = ENV['flickr_shared_secret']
  end
  
  post '/webhook' do
    $stderr.puts params.inspect
    query = params[:text].sub(/^#{params[:trigger_word]}\s*/,'')
    list = flickr.photos.search text: query
    info = flickr.photos.getInfo(photo_id: list.to_a.sample.id)
    content_type 'application/json'
    { 'text' => FlickRaw.url_b(info) }.to_json
  end
end
