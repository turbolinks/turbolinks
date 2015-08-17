#= require turbolinks/progress_bar

class Turbolinks.BrowserAdapter
  PROGRESS_BAR_DELAY = 500

  constructor: (@controller) ->
    @progressBar = new Turbolinks.ProgressBar

  visitLocation: (location) ->
    @controller.pushHistory(location)

  locationChangedByActor: (location, actor) ->
    @controller.restoreSnapshotByScrollingToSavedPosition(actor is "history")
    @controller.issueRequestForLocation(location)

  requestStarted: ->
    @showProgressBarAfterDelay()
    @progressBar.setValue(0)

  requestProgressed: (progress) ->
    @progressBar.setValue(progress)

  requestCompletedWithResponse: (response) ->
    @controller.loadResponse(response)

  requestFailedWithStatusCode: (statusCode, response) ->
    console.error "FAILED REQUEST:", statusCode

  requestFinished: ->
    @hideProgressBar()

  pageInvalidated: ->
    window.location.reload()

  # Private

  showProgressBarAfterDelay: ->
    @progressBarTimeout = setTimeout(@showProgressBar, PROGRESS_BAR_DELAY)

  showProgressBar: =>
    @progressBar.show()

  hideProgressBar: ->
    @progressBar.hide()
    clearTimeout(@progressBarTimeout)
