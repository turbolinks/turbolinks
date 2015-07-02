class Turbolinks.Cache
  constructor: ->
    @entries = {}

  put: (url, snapshot) ->
    @entries[url] = snapshot

  get: (url) ->
    @entries[url]
