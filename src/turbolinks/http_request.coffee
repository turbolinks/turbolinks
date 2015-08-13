class Turbolinks.HttpRequest
  constructor: (@delegate, @location) ->
    @xhr = new XMLHttpRequest
    @xhr.open("GET", @location.requestURL, true)
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml, application/xml")
    @xhr.onloadend = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.onabort = @requestAborted

  send: ->
    if @xhr and not @sent
      @xhr.send()
      @sent = true

  abort: ->
    if @xhr and not @sent
      @xhr.abort()

  # XMLHttpRequest events

  requestLoaded: =>
    if 200 <= @xhr.status < 300
      @delegate.requestCompletedWithResponse(@xhr.responseText)
    else
      @delegate.requestFailedWithStatusCode(@xhr.status, @xhr.responseText)
    @destroy()

  requestFailed: =>
    @delegate.requestFailedWithStatusCode(null)
    @destroy()

  requestAborted: =>
    @destroy()

  # Private

  destroy: ->
    @delegate = null
    @xhr = null
