#= require ./progress_bar

class Turbolinks.BrowserAdapter
  PROGRESS_BAR_DELAY = 500

  constructor: (@controller) ->
    @progressBar = new Turbolinks.ProgressBar

  visitProposedToLocationWithAction: (location, action) ->
    @controller.startVisitToLocationWithAction(location, action)

  visitStarted: (visit) ->
    visit.changeHistory()
    visit.issueRequest()
    visit.restoreSnapshot()

  visitRequestStarted: (visit) ->
    @progressBar.setValue(0)
    unless visit.snapshotRestored
      if visit.hasSnapshot() or visit.action isnt "restore"
        @showProgressBarAfterDelay()
      else
        @showProgressBar()

  visitRequestProgressed: (visit) ->
    @progressBar.setValue(visit.progress)

  visitRequestCompleted: (visit) ->
    visit.loadResponse()

  visitRequestFailedWithStatusCode: (visit, statusCode) ->
    if statusCode > 0
      visit.loadResponse()
    else
      @reload()

  visitRequestFinished: (visit) ->
    @hideProgressBar()

  pageInvalidated: ->
    @reload()

  # Private

  showProgressBarAfterDelay: ->
    @progressBarTimeout = setTimeout(@showProgressBar, PROGRESS_BAR_DELAY)

  showProgressBar: =>
    @progressBar.show()

  hideProgressBar: ->
    @progressBar.hide()
    clearTimeout(@progressBarTimeout)

  reload: ->
    window.location.reload()
