#= require ./http_request

class Turbolinks.Visit
  ID_PREFIX = new Date().getTime()
  id = 0

  constructor: (@controller, location, @action, @historyChanged) ->
    @promise = new Promise (@resolve, @reject) =>
      @identifier = "#{ID_PREFIX}:#{++id}"
      @location = Turbolinks.Location.box(location)
      @adapter = @controller.adapter
      @state = "initialized"

  start: ->
    if @state is "initialized"
      @state = "started"
      @adapter.visitStarted(this)

  cancel: ->
    if @state is "started"
      @request?.cancel()
      @cancelRender()
      @state = "canceled"

  complete: ->
    if @state is "started"
      @state = "completed"
      @adapter.visitCompleted?(this)
      @resolve()

  fail: ->
    if @state is "started"
      @state = "failed"
      @adapter.visitFailed?(this)
      @reject()

  then: ->
    @promise.then(arguments...)

  catch: ->
    @promise.catch(arguments...)

  changeHistory: ->
    unless @historyChanged
      method = getHistoryMethodForAction(@action)
      @controller[method](@location)
      @historyChanged = true

  issueRequest: ->
    if @shouldIssueRequest() and not @request?
      @progress = 0
      @request = new Turbolinks.HttpRequest this, @location
      @request.send()

  hasSnapshot: ->
    @controller.hasSnapshotForLocation(@location)

  restoreSnapshot: ->
    if @hasSnapshot() and not @snapshotRestored
      @render ->
        @saveSnapshot()
        if @snapshotRestored = @controller.restoreSnapshotForLocation(@location)
          @scrollToRestoredPosition()
          @adapter.visitSnapshotRestored?(this)
          @complete() unless @shouldIssueRequest()

  loadResponse: ->
    if @response?
      @render ->
        @saveSnapshot()
        if @request.failed
          @controller.loadErrorResponse(@response)
          @scrollToTop()
          @adapter.visitResponseLoaded?(this)
          @fail()
        else
          @controller.loadResponse(@response)
          @scrollToAnchor()
          @adapter.visitResponseLoaded?(this)
          @complete()

  # HTTP Request delegate

  requestStarted: ->
    @adapter.visitRequestStarted?(this)

  requestProgressed: (@progress) ->
    @adapter.visitRequestProgressed?(this)

  requestCompletedWithResponse: (@response) ->
    @adapter.visitRequestCompleted(this)

  requestFailedWithStatusCode: (statusCode, @response) ->
    @adapter.visitRequestFailedWithStatusCode(this, statusCode)

  requestFinished: ->
    @adapter.visitRequestFinished?(this)

  # Scrolling
  
  scrollToTop: ->
    @controller.scrollToPosition(0, 0)
  
  scrollToAnchor: ->
    if @location.anchor?
      @controller.scrollToAnchor(@location.anchor)
    else
      @scrollToTop()
  
  scrollToRestoredPosition: ->
    {x, y} = @restorationData ? {}
    if x? and y?
      @controller.scrollToPosition(x, y)
    else
      @scrollToTop()

  # Private

  getHistoryMethodForAction = (action) ->
    switch action
      when "advance" then "pushHistory"
      when "replace" then "replaceHistory"
      when "restore" then "pushHistory"

  shouldIssueRequest: ->
    @action is "advance" or not @hasSnapshot()

  saveSnapshot: ->
    unless @snapshotSaved
      @controller.saveSnapshot()
      @snapshotSaved = true

  render: (callback) ->
    @cancelRender()
    @frame = requestAnimationFrame =>
      @frame = null
      callback.call(this)

  cancelRender: ->
    cancelAnimationFrame(@frame) if @frame
