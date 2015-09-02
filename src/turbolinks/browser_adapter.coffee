#= require turbolinks/progress_bar

class Turbolinks.BrowserAdapter
  PROGRESS_BAR_DELAY = 500

  constructor: ->
    @progressBar = new Turbolinks.ProgressBar

  visitStarted: (visit) ->
    visit.changeHistory()
    visit.issueRequest()
    visit.restoreSnapshot()

  visitRequestStarted: (visit) ->
    @showProgressBarAfterDelay() unless visit.snapshotRestored
    @progressBar.setValue(0)
  
  visitRequestProgressed: (visit) ->
    @progressBar.setValue(visit.progress)

  visitRequestCompleted: (visit) ->
    visit.loadResponse()
  
  visitRequestFailedWithStatusCode: (visit, statusCode) ->
    visit.loadResponse()
  
  visitRequestFinished: (visit) ->
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
