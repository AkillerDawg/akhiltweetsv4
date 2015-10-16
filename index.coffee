express = require 'express'
qs      = require 'querystring'
app     = express()
http    = require('http').Server(app)
config  = require './config'
twitter = new require('twitter') config.twitter

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'
app.use '/public', express.static "#{__dirname}/public"

app.get '/', (i, o) ->
  o.render 'index'

getTweetInfo = (tweet) ->
  ret = {id: tweet.id_str, text: tweet.text}
  if tweet.place?
    ret.place = tweet.place.full_name
  ret

getTweets = (username, sinceId, cb) ->
  makeParams = (next) ->
    ret = {q: "@#{username}", count: 100}
    if next?
      ret.max_id = qs.parse(next[1...]).max_id
    if sinceId?
      ret.since_id = sinceId
    ret

  _get = (pool, next) ->
    twitter.get 'search/tweets', makeParams(next), (err, tweets) ->
      console.log err, tweets
      pool ?= []
      if tweets? and tweets.statuses? and tweets.statuses.length > 0
        pool = pool.concat tweets.statuses
        if tweets.search_metadata.next_results
          if pool.length < 100
            return _get pool, tweets.search_metadata.next_results
      cb (getTweetInfo x for x in pool[...100])

  _get()

app.get '/tweets', (i, o) ->
  getTweets i.query.username, null, (tweets) ->
    o.render 'tweets',
      tweets: tweets
      username: i.query.username
      apiKey: config.googleMaps

app.get '/poll', (i, o) ->
  getTweets i.query.username, i.query.sinceId, (tweets) ->
    o.json
      tweets: tweets

http.listen 3000, ->
  console.log 'listening on *:3000'
