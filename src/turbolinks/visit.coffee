#= require turbolinks/http_request

class Turbolinks.Visit
  constructor: (@controller, previousLocation, location, @action, @historyChanged) ->
    @previousLocation = Turbolinks.Location.box(previousLocation)
    @location = Turbolinks.Location.box(location)
    @adapter = @controller.adapter
  
  start: ->
    unless @started
      @promise = new Promise (@resolve, @reject) =>
        @started = true
        @adapter.visitStarted(this)

  cancel: ->
    if @started and not @canceled
      @request?.cancel()
      @canceled = true

  changeHistory: (method = "pushHistory") ->
    unless @historyChanged
      @controller[method](@location)
      @historyChanged = true

  issueRequest: ->
    if @shouldIssueRequest() and not @request?
      @progress = 0
      @request = new Turbolinks.HttpRequest this, @location
      @request.send()
  
  restoreSnapshot: ->
    unless @snapshotRestored
      @saveSnapshot()
      @snapshotRestored = @controller.restoreSnapshotForLocationWithAction(@location, @action)
      @resolve() unless @shouldIssueRequest()

  loadResponse: ->
    if @response?
      @saveSnapshot()
      if @request.failed
        @controller.loadErrorResponse(@response)
        @reject()
      else
        @controller.loadResponse(@response)
        @resolve()

  # HTTP Request delegate
  
  requestStarted: ->
    @adapter.visitRequestStarted(this)

  requestProgressed: (@progress) ->
    @adapter.visitRequestProgressed(this)

  requestCompletedWithResponse: (@response) ->
    @adapter.visitRequestCompleted(this)

  requestFailedWithStatusCode: (statusCode, @response) ->
    @adapter.visitRequestFailedWithStatusCode(this, statusCode)

  requestFinished: ->
    @adapter.visitRequestFinished(this)
    
  # Private
  
  shouldIssueRequest: ->
    @action is "advance" or not @hasSnapshot()

  hasSnapshot: ->
    @controller.hasSnapshotForLocation(@location)

  saveSnapshot: ->
    unless @snapshotSaved
      @controller.saveSnapshotForLocation(@previousLocation)
      @snapshotSaved = true