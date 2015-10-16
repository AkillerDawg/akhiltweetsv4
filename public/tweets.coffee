map = null
geocoder = null
infoWindow = null

geocodeNew = (address, cb) ->
  geocoder.geocode {address: address}, (results, status) ->
    if status is google.maps.GeocoderStatus.OK
      unless status is google.maps.GeocoderStatus.ZERO_RESULTS
        return cb results[0].geometry.location
    cb null

geocodeCache = {}

geocode = (address, cb) ->
  if address of geocodeCache
    cb geocodeCache[address]
  else
    geocodeNew address, (loc) ->
      if loc
        geocodeCache[address] = loc
      cb loc

renderTweet = (tweet) ->
  url = "http://twitter.com/statuses/#{tweet.id}"
  "<a target='_blank' href='#{url}'>#{tweet.text}</a>"

makeMarker = (map, loc, tweet) ->
  marker = new google.maps.Marker
    map: map
    position: loc
    title: tweet.place or "No Man's Land"
  marker.addListener 'click', ->
    infoWindow.close() if infoWindow
    infoWindow = new google.maps.InfoWindow {content: renderTweet tweet}
    infoWindow.open map, marker

antarcticaCounter = 0

antarctica = ->
  lat: -80
  lng: antarcticaCounter++ * 7

addTweet = (tweet) ->
  if tweet.place
    geocode tweet.place, (loc) ->
      makeMarker map, loc, tweet
  else
    makeMarker map, antarctica(), tweet

lastTweetId = null

addTweets = (tweets) ->
  if tweets and tweets.length > 0
    lastTweetId = tweets[0].id
    for t in tweets
      addTweet t

_poll = ->
  $.getJSON '/poll',
    username: window.username
    sinceId: lastTweetId
  , (d) ->
    addTweets d.tweets
    poll()

poll = -> setTimeout _poll, 5000

window.init = ->
  map = new google.maps.Map $('#map')[0],
    zoom: 2
    center: {lat: -25.363, lng: 131.044}

  geocoder = new google.maps.Geocoder()
  addTweets window.tweets
  poll()
