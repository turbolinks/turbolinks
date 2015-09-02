#= require turbolinks/http_request

class Turbolinks.Visit
  constructor: (@controller, location, @action, @historyChanged) ->
    @location = Turbolinks.Location.box(location)
    @adapter = @controller.adapter
  
  start: ->
    unless @started
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
      @snapshotRestored = @controller.restoreSnapshotForVisit(this)

  loadResponse: ->
    if @response?
      if @request.failed
        @controller.loadErrorResponse(@response)
      else
        @controller.loadResponse(@response)

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
