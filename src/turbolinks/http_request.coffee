class Turbolinks.HttpRequest
  constructor: (@delegate, location) ->
    @location = Turbolinks.Location.box(location)
    @xhr = new XMLHttpRequest
    @xhr.open("GET", @location.requestURL, true)
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml, application/xml")
    @xhr.onprogress = @requestProgressed
    @xhr.onloadend = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.onabort = @requestAborted

  send: ->
    if @xhr and not @sent
      @setProgress(0)
      @xhr.send()
      @sent = true
      @delegate.requestStarted?()

  abort: ->
    if @xhr and @sent
      @xhr.abort()

  # XMLHttpRequest events

  requestProgressed: (event) =>
    if event.lengthComputable
      @setProgress(event.loaded / event.total)

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

  setProgress: (progress) ->
    @progress = progress
    @delegate.requestProgressed?(@progress)

  destroy: ->
    @setProgress(1)
    @delegate.requestFinished?()
    @delegate = null
    @xhr = null
