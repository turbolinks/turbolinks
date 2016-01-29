#= require ./http_request

class Turbolinks.Visit
  constructor: (@controller, location, @action) ->
    @promise = new Promise (@resolve, @reject) =>
      @identifier = Turbolinks.uuid()
      @location = Turbolinks.Location.box(location)
      @adapter = @controller.adapter
      @state = "initialized"
      @metrics = {}

  start: ->
    if @state is "initialized"
      @startMetric("visit")
      @state = "started"
      @adapter.visitStarted(this)

  cancel: ->
    if @state is "started"
      @request?.cancel()
      @cancelRender()
      @state = "canceled"

  complete: ->
    if @state is "started"
      @endMetric("visit")
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

  getCachedSnapshot: ->
    snapshot = @controller.getCachedSnapshotForLocation(@location)
    return if @location.anchor? and not snapshot?.hasAnchor(@location.anchor)
    snapshot

  hasCachedSnapshot: ->
    @getCachedSnapshot()?

  loadCachedSnapshot: ->
    if snapshot = @getCachedSnapshot()
      isPreview = @shouldIssueRequest()
      @render ->
        @cacheSnapshot()
        @controller.render({snapshot, isPreview}, @performScroll)
        @adapter.visitRendered?(this)
        @complete() unless isPreview

  loadResponse: ->
    if @response?
      @render ->
        @cacheSnapshot()
        if @request.failed
          @controller.render(html: @response, @performScroll)
          @adapter.visitRendered?(this)
          @fail()
        else
          @controller.render(snapshot: @response, @performScroll)
          @adapter.visitRendered?(this)
          @complete()

  followRedirect: ->
    if @redirectedToLocation and not @followedRedirect
      @location = @redirectedToLocation
      @controller.replaceHistoryWithLocationAndRestorationIdentifier(@redirectedToLocation, @restorationIdentifier)
      @followedRedirect = true

  # HTTP Request delegate

  requestStarted: ->
    @startMetric("request")
    @adapter.visitRequestStarted?(this)

  requestProgressed: (@progress) ->
    @adapter.visitRequestProgressed?(this)

  requestCompletedWithResponse: (@response, redirectedToLocation) ->
    @redirectedToLocation = Turbolinks.Location.box(redirectedToLocation) if redirectedToLocation?
    @adapter.visitRequestCompleted(this)

  requestFailedWithStatusCode: (statusCode, @response) ->
    @adapter.visitRequestFailedWithStatusCode(this, statusCode)

  requestFinished: ->
    @endMetric("request")
    @adapter.visitRequestFinished?(this)

  # Scrolling

  performScroll: =>
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

  # Instrumentation

  startMetric: (name) ->
    @metrics[name] =
      start: new Date

  endMetric: (name) ->
    if metric = @metrics[name]
      metric.end = new Date
      metric.duration = metric.end - metric.start

  getMetrics: ->
    metrics = Turbolinks.copyObject(@metrics)
    metrics.fromCache = not @shouldIssueRequest()
    metrics

  # Private

  getHistoryMethodForAction = (action) ->
    switch action
      when "replace" then "replaceHistoryWithLocationAndRestorationIdentifier"
      when "advance", "restore" then "pushHistoryWithLocationAndRestorationIdentifier"

  shouldIssueRequest: ->
    if @action is "restore"
      not @hasCachedSnapshot()
    else
      true

  cacheSnapshot: ->
    unless @snapshotCached
      @controller.cacheSnapshot()
      @snapshotCached = true

  render: (callback) ->
    @cancelRender()
    @frame = requestAnimationFrame =>
      @frame = null
      callback.call(this)

  cancelRender: ->
    cancelAnimationFrame(@frame) if @frame
