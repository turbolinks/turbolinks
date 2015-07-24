class Turbolinks.Cache
  constructor: ->
    @entries = {}

  put: (location, snapshot) ->
    location = Turbolinks.Location.box(location)
    @entries[location.toCacheKey()] = snapshot

  get: (location) ->
    location = Turbolinks.Location.box(location)
    @entries[location.toCacheKey()]
