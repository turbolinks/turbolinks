#= require turbolinks/progress_bar

class Turbolinks.BrowserAdapter
  constructor: (@controller) ->
    @progressBar = new Turbolinks.ProgressBar

  visitLocation: (location) ->
    @controller.pushHistory(location)

  locationChangedByActor: (location, actor) ->
    @controller.restoreSnapshotByScrollingToSavedPosition(actor is "history")
    @controller.issueRequestForLocation(location)

  requestStarted: ->
    @progressBar.show()

  requestProgressed: (progress) ->
    @progressBar.setValue(progress)

  requestCompletedWithResponse: (response) ->
    @controller.loadResponse(response)

  requestFailedWithStatusCode: (statusCode, response) ->
    console.error "FAILED REQUEST:", statusCode

  requestFinished: ->
    @progressBar.hide()

  pageInvalidated: ->
    window.location.reload()
