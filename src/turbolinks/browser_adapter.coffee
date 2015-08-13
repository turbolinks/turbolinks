class Turbolinks.BrowserAdapter
  constructor: (@controller) ->

  visitLocation: (location) ->
    @controller.pushHistory(location)

  locationChangedByActor: (location, actor) ->
    @controller.restoreSnapshotByScrollingToSavedPosition(actor is "history")
    @controller.issueRequestForLocation(location)

  requestCompletedWithResponse: (response) ->
    @controller.loadResponse(response)

  requestFailedWithStatusCode: (statusCode, response) ->
    console.error "FAILED REQUEST:", statusCode

  pageInvalidated: ->
    window.location.reload()
