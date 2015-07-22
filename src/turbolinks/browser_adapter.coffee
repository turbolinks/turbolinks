class Turbolinks.BrowserAdapter
  constructor: (@controller) ->

  visitLocation: (location) ->
    @controller.pushHistory(location)

  locationChanged: (location) ->
    @issueRequestForLocation(location)
    @controller.restoreSnapshot()

  # Private

  issueRequestForLocation: (location) ->
    @xhr?.abort()
    @xhr = new XMLHttpRequest
    @xhr.open("GET", location, true)
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml, application/xml")
    @xhr.onload = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.send()

  requestLoaded: =>
    @controller.loadResponse(@xhr.responseText)
    @xhr = null

  requestFailed: (error) =>
    @xhr = null
