class Turbolinks.BrowserAdapter
  constructor: (@delegate) ->

  visitLocation: (url) ->
    @delegate.getHistoryForAdapter().push(url)

  locationChanged: (url) ->
    @request(url)

  snapshotRestored: ->

  # Private

  request: (url) ->
    @xhr?.abort()
    @xhr = new XMLHttpRequest
    @xhr.open("GET", url, true)
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml, application/xml")
    @xhr.onload = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.send()

  requestLoaded: =>
    @delegate.adapterLoadedResponse(@xhr.responseText)
    @xhr = null

  requestFailed: (error) =>
    @xhr = null
