#= require ./http_request

class Turbolinks.Visit
  constructor: (@controller, location, @action) ->
    @promise = new Promise (@resolve, @reject) =>
      @identifier = Turbolinks.uuid()
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
      actionForHistory = if @location.isEqualTo(@referrer) then "replace" else @action
      method = getHistoryMethodForAction(actionForHistory)
      @controller[method](@location, @restorationIdentifier)
      @historyChanged = true

  issueRequest: ->
    if @shouldIssueRequest() and not @request?
      @progress = 0
      @request = new Turbolinks.HttpRequest this, @location, @referrer
      @request.send()

  hasSnapshot: ->
    if snapshot = @controller.getSnapshotForLocation(@location)
      if @location.anchor?
        snapshot.hasAnchor(@location.anchor)
      else
        true
    else
      false

  restoreSnapshot: ->
    if @hasSnapshot() and not @snapshotRestored
      @render ->
        @saveSnapshot()
        if @snapshotRestored = @controller.restoreSnapshotForLocation(@location)
          @performScroll()
          @adapter.visitSnapshotRestored?(this)
          @complete() unless @shouldIssueRequest()

  loadResponse: ->
    if @response?
      @render ->
        @saveSnapshot()
        if @request.failed
          @controller.loadErrorResponse(@response)
          @performScroll()
          @adapter.visitResponseLoaded?(this)
          @fail()
        else
          @controller.loadResponse(@response)
          @performScroll()
          @adapter.visitResponseLoaded?(this)
          @complete()

  followRedirect: ->
    if @redirectedToLocation and not @followedRedirect
      @location = @redirectedToLocation
      @controller.replaceHistoryWithLocationAndRestorationIdentifier(@redirectedToLocation, @restorationIdentifier)
      @followedRedirect = true

  # HTTP Request delegate

  requestStarted: ->
    @adapter.visitRequestStarted?(this)

  requestProgressed: (@progress) ->
    @adapter.visitRequestProgressed?(this)

  requestCompletedWithResponse: (@response, redirectedToLocation) ->
    @redirectedToLocation = Turbolinks.Location.box(redirectedToLocation) if redirectedToLocation?
    @adapter.visitRequestCompleted(this)

  requestFailedWithStatusCode: (statusCode, @response) ->
    @adapter.visitRequestFailedWithStatusCode(this, statusCode)

  requestFinished: ->
    @adapter.visitRequestFinished?(this)

  # Scrolling

  performScroll: ->
    unless @scrolled
      if @action is "restore"
        @scrollToRestoredPosition() or @scrollToTop()
      else
        @scrollToAnchor() or @scrollToTop()
      @scrolled = true

  scrollToRestoredPosition: ->
    position = @restorationData?.scrollPosition
    if position?
      @controller.scrollToPosition(position)
      true

  scrollToAnchor: ->
    if @location.anchor?
      @controller.scrollToAnchor(@location.anchor)
      true

  scrollToTop: ->
    @controller.scrollToPosition(x: 0, y: 0)

  # Private

  getHistoryMethodForAction = (action) ->
    switch action
      when "replace" then "replaceHistoryWithLocationAndRestorationIdentifier"
      when "advance", "restore" then "pushHistoryWithLocationAndRestorationIdentifier"

  shouldIssueRequest: ->
    if @action is "restore"
      not @hasSnapshot()
    else
      true

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
