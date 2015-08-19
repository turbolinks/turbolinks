class Turbolinks.HttpRequest
  constructor: (@delegate, location) ->
    @url = Turbolinks.Location.box(location).requestURL
    @createXHR()

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
    @endRequest =>
      if 200 <= @xhr.status < 300
        @delegate.requestCompletedWithResponse(@xhr.responseText)
      else
        @delegate.requestFailedWithStatusCode(@xhr.status, @xhr.responseText)

  requestFailed: =>
    @endRequest =>
      @delegate.requestFailedWithStatusCode(null)

  requestAborted: =>
    @endRequest()

  # Private

  createXHR: ->
    @xhr = new XMLHttpRequest
    @xhr.open("GET", @url, true)
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml, application/xml")
    @xhr.onprogress = @requestProgressed
    @xhr.onloadend = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.onabort = @requestAborted

  endRequest: (callback) ->
    @notifyApplicationAfterRequestEnd()
    callback?.call(this)
    @destroy()

  notifyApplicationBeforeRequestStart: ->
    Turbolinks.dispatch("turbolinks:request-start", data: { url: @url, xhr: @xhr })

  notifyApplicationAfterRequestEnd: ->
    Turbolinks.dispatch("turbolinks:request-end", data: { url: @url, xhr: @xhr })

  setProgress: (progress) ->
    @progress = progress
    @delegate.requestProgressed?(@progress)

  destroy: ->
    @setProgress(1)
    @delegate.requestFinished?()
    @delegate = null
    @xhr = null
