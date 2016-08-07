require 'capybara'
require 'capybara/dsl'


def setup_client(config)
  Twitter::REST::Client.new do |c|
    c.consumer_key        = config['consumer_key']
    c.consumer_secret     = config['consumer_secret']
    c.access_token        = config['access_token']
    c.access_token_secret = config['access_token_secret']
  end
end


class Unfollow
  def initialize(client)
    @client = client
  end

  def because(them, msg)
    puts "#{them.name} (@#{them.screen_name}) http://twitter.com/@#{them.screen_name}"
    puts "\t#{msg}"
    @client.unfollow(them.screen_name)
  end
end


class Login
  def self.do(config)
    Capybara.run_server = false
    Capybara.current_driver = :selenium
    Capybara.app_host = 'http://www.twitter.com'
    Capybara.default_max_wait_time = 10
    session = Capybara::Session.new(:selenium)

    session.visit '/login'
    session.find(".js-username-field").set(config['username'])
    session.find(".js-password-field").set(config['password'])
    session.find(".signin-wrapper .submit").click
  end
end


class Check
  include Capybara::DSL
  def initialize(client, you)
    @client = client
    @you = you
  end

  def havent_talked_to(them)
    begin
      visit("/search?f=tweets&q=@#{@you.screen_name}+@#{them.screen_name}")
      find("ol#stream-items-id li.stream-item:first-child")
      return false
    rescue Capybara::ElementNotFound
      return true
    end
  end

  def dont_follow_you(them)
    begin
      visit("/@#{them.screen_name}")
      find(".ProfileHeaderCard .FollowStatus")
      return false
    rescue Capybara::ElementNotFound
      return true
    end
  end

  def havent_tweeted_recently(them)
    three_months_ago = Time.now.to_i - 3*60*60*24*31
    tweet_created    = @client.user_timeline(them, :include_rts=>false)[0].created_at.to_i
    return tweet_created < three_months_ago
  end

end
