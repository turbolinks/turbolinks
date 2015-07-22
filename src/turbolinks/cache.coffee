class Turbolinks.Cache
  constructor: ->
    @entries = {}

  put: (location, snapshot) ->
    @entries[location] = snapshot

  get: (url) ->
    @entries[location]
