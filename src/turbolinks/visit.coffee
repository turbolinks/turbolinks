#= require turbolinks/http_request

class Turbolinks.Visit
  constructor: (@controller, previousLocation, location, @action, @historyChanged) ->
    @promise = new Promise (@resolve, @reject) =>
      @previousLocation = Turbolinks.Location.box(previousLocation)
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

  then: ->
    @promise.then(arguments...)

  catch: ->
    @promise.catch(arguments...)

  changeHistory: (method = "pushHistory") ->
    unless @historyChanged
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
    unless @snapshotRestored
      @saveSnapshot()
      if @snapshotRestored = @controller.restoreSnapshotForLocationWithAction(@location, @action)
        @adapter.visitSnapshotRestored?(this)
      unless @shouldIssueRequest()
        @resolve()

  loadResponse: ->
    if @response?
      @saveSnapshot()
      if @request.failed
        @controller.loadErrorResponse(@response)
        @reject()
      else
        @controller.loadResponse(@response)
        @resolve()
      @adapter.visitResponseLoaded?(this)

  # HTTP Request delegate
  
  requestStarted: ->
    @adapter.visitRequestStarted(this)

  requestProgressed: (@progress) ->
    @adapter.visitRequestProgressed?(this)

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