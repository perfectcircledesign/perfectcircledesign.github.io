require 'rbconfig'
VERSION_BAND = '2.0.0'

gsub_file 'Gemfile', "gem 'jquery-rails'", "gem 'jquery-rails', '~> 2.0.0'"
append_file 'Gemfile', <<-GEMFILE
gem 'json', '1.8.1'
gem 'babosa', '0.3.11'
gem 'net-ssh', '2.9.2'
gem 'rack-cache', '1.2'


GEMFILE

# We want to ensure that you have an ExecJS runtime available!
begin
  run 'bundle install'
  require 'execjs'
  ::ExecJS::Runtimes.autodetect
rescue
  require 'pathname'
  if Pathname.new(destination_root.to_s).join('Gemfile').read =~ /therubyracer/
    gsub_file 'Gemfile', "# gem 'therubyracer'", "gem 'therubyracer'"
  else
    append_file 'Gemfile', <<-GEMFILE

group :assets do
  # Added by Refinery. We want to ensure that you have an ExecJS runtime available!
  gem 'therubyracer'
end
GEMFILE
  end
end

append_file 'Gemfile', <<-GEMFILE

# Refinery CMS
gem 'refinerycms', :git => 'git://github.com/perfectcircledesign/refinerycms.git', :branch => '2-0-stable'

# Specify additional Refinery CMS Extensions here (all optional):
gem 'refinerycms-i18n', '~> #{VERSION_BAND}'
#  gem 'refinerycms-blog', '~> #{VERSION_BAND}'
#  gem 'refinerycms-inquiries', '~> #{VERSION_BAND}'
#  gem 'refinerycms-search', '~> #{VERSION_BAND}'
#  gem 'refinerycms-page-images', '~> #{VERSION_BAND}'

gem 'bcrypt-ruby', '3.0.1'
GEMFILE

gems = []
if yes? "Do you want to add the pods engine?"
  gems << 'refinerycms-pods'
  gem 'refinerycms-pods', '~> 2.1.0'
  gem 'refinerycms-videos', '~> 2.0.1'
  gem 'refinerycms-portfolio', :git => 'git://github.com/perfectcircledesign/refinerycms-portfolio.git', :branch => '2-0-stable'
else
  if yes? "Do you want to add the videos engine?"
    gems << 'refinerycms-videos'
    gem 'refinerycms-videos', '~> 2.0.1'
  else
    if yes? "Do you want to add the portfolio engine?"
      gems << 'refinerycms-portfolio'
      gem 'refinerycms-portfolio', :git => 'git://github.com/perfectcircledesign/refinerycms-portfolio.git', :branch => '2-0-stable'
    end
  end
end

if yes? "Do you want a news engine?"
  gems << 'refinerycms-news'
  gem "refinerycms-news", '~> 2.0.0'

end
if yes? "Do you want a blog engine?"
  gems << 'refinerycms-blog'
  gem 'refinerycms-blog', '~> 2.0.0'
  #Locked For Blog Engine
  gem "acts-as-taggable-on", "3.0.1"
  gem "rails_autolink", "1.1.4"
end
if yes? "Do you want the banner engine?"
  gems << 'refinerycms-pc_banners'
   gem 'refinerycms-pc_banners', '~> 2.0.2'
end
if yes? "Do you want the inquiries engine?"
  gems << 'refinerycms-inquiries'
  gem 'refinerycms-inquiries', '~> 2.0.0'
end
if yes? "Do you want to use simple form"
  gems << 'simple_form'
  gem 'simple_form', '~> 2.0.2'
end


run "bundle install"


 if gems.include?('refinerycms-pods')
  generate "refinery:pods"
  generate "refinery:videos"
  generate "refinery:portfolio"
end

if gems.include?('refinerycms-vidoes')
  generate "refinery:videos"
end

if gems.include?('refinerycms-portfolio')
   generate "refinery:portfolio"
end

if gems.include?('refinerycms-news')
  generate "refinery:news"
end

if gems.include?('refinerycms-blog')
  generate 'refinery:blog'
end

if gems.include?('refinerycms-pc_banners')
  generate 'refinery:banners'
end

if gems.include?('refinerycms-inquiries')
  generate 'refinery:inquiries'
end

if gems.include?('simple_form')
  generate 'simple_form:install --bootstrap'
end

append_file 'Gemfile', <<-GEMFILE

#Locked Gems
gem 'refinerycms-settings', '2.0.1'

#Used Gems
# Seed our data smartly
gem 'seed-fu', '~> 2.2.0'

# Make our RefineryCMS page seeding a bit eaiser
gem 'refinerycms-page_seeder', '~> 0.0.1'

# Send errors to our Errbit server
gem 'airbrake', '~> 3.1.6'

# Colorbox support for asset pipeline
gem "jquery-colorbox-rails", "0.1.4"

# Required to get Refinery working on Heroku
gem 'fog', '~> 0.8.1'

#Monitoring
gem 'newrelic_rpm'

group :development do
     gem 'better_errors', '1.1.0'
     gem "binding_of_caller"
     gem "commands"
end

group :production do
  gem 'pg', '0.17.1'
  gem 'puma'
end



GEMFILE


create_file "config/initializers/errbit.rb"
empty_directory  "db/fixtures"
create_file "db/fixtures/001_pages.rb"
create_file "Procfile"
create_file "config/puma.rb"


#Setup for heroku
insert_into_file "config/environments/production.rb", "ActionMailer::Base.smtp_settings = {
    :from           => 'no-reply@newden.co.za',
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    :user_name      => ENV['SENDGRID_USERNAME'],
    :password       => ENV['SENDGRID_PASSWORD'],
    :domain         => 'heroku.com'
}
ActionMailer::Base.delivery_method = :smtp
", :after => "Rails::Initializer.run do |config|\n"

insert_into_file "Procfile", "web: bundle exec puma -C config/puma.rb"

insert_into_file "config/puma.rb", "workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
"


run 'bundle update'
rake 'db:create'
generate "refinery:cms --fresh-installation #{ARGV.join(' ')}"

#Overriding Refinery Pages
rake 'refinery:override view=layouts/application'

say <<-SAY
  ============================================================================
  What you need to do   
    1. Create app on Errbit and copy to the errbit.rb file 
    2. Comment out Bundler.require(*Rails.groups(:assets => %w(development test)))
    3. Uncomment Bundler.require(:default, :assets, Rails.env)
    4. Add config.assets.initialize_on_precompile = false to the application.rb 
  ============================================================================
SAY
