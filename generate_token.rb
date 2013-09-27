require "rubygems"
require "sinatra"
require "pocket"

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

Pocket.configure do |config|
  config.consumer_key = 'yourconsumerkey'
end

get '/reset' do
  puts "GET /reset"
  session.clear
  redirect "/"
end

get "/" do
  puts "GET /"
  puts "session: #{session}"
  
  if session[:access_token]
    'Access token: ' + session[:access_token] +
    '<br /><a href="/reset">Reset session</a>'
  else
    '<a href="/oauth/connect">Connect with Pocket</a>'
  end
end

get "/oauth/connect" do
  puts "OAUTH CONNECT"
  session[:code] = Pocket.get_code(:redirect_uri => CALLBACK_URL)
  new_url = Pocket.authorize_url(:code => session[:code], :redirect_uri => CALLBACK_URL)
  puts "new_url: #{new_url}"
  puts "session: #{session}"
  redirect new_url
end

get "/oauth/callback" do
  puts "OAUTH CALLBACK"
  puts "request.url: #{request.url}"
  puts "request.body: #{request.body.read}"
  access_token = Pocket.get_access_token(session[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = access_token
  puts "#{access_token}"
  puts "session: #{session}"
  redirect "/"
end
