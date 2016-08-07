# twitter_unfollow

Use to automatically unfollow
* people who dont follow you back, or
* people you haven't talked to publically, or
* people who haven't posted in 3 months

**Only working on Ubuntu 14**

## setup

```
git clone http://github.com/LynnCo/twitter_unfollow.git
cd twitter_unfollow
bundle install
cp yaml/config.example.yaml yaml/config.yaml
cp yaml/exceptions.example.yaml yaml/exceptions.example.yaml
subl yaml/config.yaml
ruby main.rb
```

(some more assembly may be required)
