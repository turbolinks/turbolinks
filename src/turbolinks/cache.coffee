class Turbolinks.Cache
  constructor: ->
    @entries = {}

  put: (location, snapshot) ->
    @entries[location] = snapshot

  get: (location) ->
    @entries[location]
