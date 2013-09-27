pocket-octopress
================

Pocket API Parser for Octopress Blogs based on pocket-ruby gem

```diff
--- a/Gemfile
+++ b/Gemfile
@@ -17,3 +17,6 @@ group :development do
 end
 
 gem 'sinatra', '~> 1.4.2'
+gem 'pocket-ruby'
+gem 'active_support'
+gem 'i18n'
```

``` ruby generate_token.rb
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
```

```diff
--- a/Rakefile
+++ b/Rakefile
@@ -1,6 +1,8 @@
 require "rubygems"
 require "bundler/setup"
 require "stringex"
+require "active_support/all"
+require "pocket"
 
 ## -- Rsync Deploy config -- ##
 # Be sure your public key is listed in your server's ~/.ssh/authorized_keys file
@@ -27,6 +29,10 @@ new_post_ext    = "markdown"  # default new post file extension when using the n
 new_page_ext    = "markdown"  # default new page file extension when using the new_page task
 server_port     = "4000"      # port for preview server eg. localhost:4000
 
+## Pocket Configuration
+consumer_key = 'yourconsumerkey'
+access_token = 'youraccesstoken'
+
 
 desc "Initial setup for Octopress: copies the default theme into the path of Jekyll's generator. Rake install defaults to rake install[classic] to install a different theme run rake install[some_theme_name]"
 task :install, :theme do |t, args|
@@ -115,6 +121,50 @@ task :new_post, :title do |t, args|
   end
 end
 
+desc "Generate blogpost with Pocket links for your blog. e.g. weekly, monthly linklists"
+task :new_pocket, :timerange do |t, args|
+  if args.timerange
+    timerange = args.timerange
+  else
+    timerange = get_stdin("Enter timerange in days: ")
+  end
+  raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
+  mkdir_p "#{source_dir}/#{posts_dir}"
+  title = "Pocket links from #{timerange.to_i.days.ago.strftime('%Y-%m-%d')} to #{Time.now.strftime('%Y-%m-%d')}"
+  filename = "#{source_dir}/#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
+  if File.exist?(filename)
+    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
+  end
+
+  Pocket.configure do |config|
+    config.consumer_key = consumer_key
+  end
+
+  client = Pocket.client(:access_token => access_token)
+  info = client.retrieve :detailType => :article
+
+  puts "Creating new post: #{filename}"
+  open(filename, 'w') do |post|
+    post.puts "---"
+    post.puts "layout: post"
+    post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
+    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
+    post.puts "comments: true"
+    post.puts "categories: [Pocket, Links, Favorites]"
+    post.puts "---"
+    info["list"].each do |k,v|
+      unless v["time_added"].to_i < timerange.to_i.days.ago.to_i
+        post.puts "*   #{v["resolved_title"].to_s}"
+        post.puts "    "
+        post.puts "    >#{v["excerpt"].to_s}"
+        post.puts "    "
+        post.puts "    #{v["resolved_url"].to_s}"
+        post.puts "    "
+      end
+    end
+  end
+end
+
 # usage rake new_page[my-new-page] or rake new_page[my-new-page.html] or rake new_page (defaults to "new-page.markdown")
 desc "Create a new page in #{source_dir}/(filename)/index.#{new_page_ext}"
 task :new_page, :filename do |t, args|
```