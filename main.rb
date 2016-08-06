require 'yaml'
require 'twitter'
require 'bundler/inline'
require 'rails/all'
require 'capybara'
require 'capybara/dsl'

config = YAML.load_file('config.yaml')
exceptions = YAML.load_file('exceptions.yaml')

#############
# FUNCTIONS #
#############


class Login
  include Capybara::DSL
  def do(username, password)
    visit '/login'
    find(".js-username-field").set(username)
    find(".js-password-field").set(password)
    find(".signin-wrapper .submit").click
  end
end

class Check
  include Capybara::DSL

  def self.you_havent_talked
    begin
      visit("/search?f=tweets&q=@#{$you.screen_name}+@#{$them.screen_name}")
      find("ol#stream-items-id li.stream-item:first-child")
      return false
    rescue Capybara::ElementNotFound
      return true
    end
  end

  def self.they_dont_follow_you
    begin
      visit("/@#{$them.screen_name}")
      find(".ProfileHeaderCard .FollowStatus")
      return false
    rescue Capybara::ElementNotFound
      return true
    end
  end

  def self.they_havent_tweeted_recently
    three_months_ago = Time.now.to_i - 3*60*60*24*31
    tweet_created = $t.user_timeline($them, :include_rts=>false)[0].created_at.to_i
    return tweet_created < three_months_ago
  end

end

def unfollow_because(msg)
  puts "#{$them.name} (@#{$them.screen_name}) http://twitter.com/@#{$them.screen_name}"
  puts "\t#{msg}"
  $t.unfollow($them.screen_name)
end


#########
# SETUP #
#########


# webkit
Capybara.run_server = false
Capybara.current_driver = :selenium
Capybara.app_host = 'http://www.twitter.com'
Capybara.default_max_wait_time = 10
Login.new.do(config['username'], config['password'])

# api
$t = Twitter::REST::Client.new do |c|
  c.consumer_key        = config['consumer_key']
  c.consumer_secret     = config['consumer_secret']
  c.access_token        = config['access_token']
  c.access_token_secret = config['access_token_secret']
end
$you = $t.user
following = $t.friend_ids($you.id).to_a


################
# DO THE THING #
################


e = 0
offset = following.length*config['offset']/100
following = following.slice(offset, following.length)
puts "Starting script offset by the #{offset} (#{config['offset']}%) most recent follows"
time_start = Time.now

following.shuffle.each_with_index do |id,i|
  include ActionView::Helpers::DateHelper

  $them = $t.user(id)
  percent = 100*(i)/(following.length)
  time = distance_of_time_in_words_to_now(time_start)
  puts "#{i}/#{following.length} (#{percent}%) -- Started #{time} ago"

  if exceptions.include? $them.screen_name
    next
  end

  if Check.they_dont_follow_you
    unfollow_because "They don't follow you"
  elsif Check.they_havent_tweeted_recently
    unfollow_because "They haven't tweeted in 3 months"
  elsif Check.you_havent_talked
    unfollow_because "You haven't talked publically"
  end
end
