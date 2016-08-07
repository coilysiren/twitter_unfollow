require 'yaml'
require 'rails/all'
require_relative 'lib'


def main
  include ActionView::Helpers::DateHelper
  time_start = Time.now
  config     = YAML.load_file('yaml/config.yaml')
  exceptions = YAML.load_file('yaml/exceptions.yaml')

  client     = setup_client(config)
  you        = client.user
  following  = client.friend_ids(you.id).to_a
  offset     = following.length*config['offset']/100
  following  = following.slice(offset, following.length)
  session    = Login.do(config)
  check      = Check.new(client, you, session)
  unfollow   = Unfollow.new(client)

  puts "Starting script offset by the #{offset} (#{config['offset']}%) most recent follows"

  following.shuffle.each_with_index do |id,i|
    them    = client.user(id)
    percent = 100*(i)/(following.length)
    time    = distance_of_time_in_words_to_now(time_start)
    puts "#{i}/#{following.length} (#{percent}%) -- Started #{time} ago"

    if exceptions.include? them.screen_name
      next
    end

    if check.dont_follow_you(them)
      unfollow.because "They don't follow you"
    elsif check.havent_tweeted_recently(them)
      unfollow.because "They haven't tweeted in 3 months"
    elsif check.havent_talked_to(them)
      unfollow.because "You haven't talked publically"
    end
  end
end


if __FILE__ == $0
  main
end
