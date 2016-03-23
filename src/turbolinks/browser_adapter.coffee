#= require ./http_request
#= require ./progress_bar

class Turbolinks.BrowserAdapter
  {NETWORK_FAILURE, TIMEOUT_FAILURE} = Turbolinks.HttpRequest
  PROGRESS_BAR_DELAY = 500

  constructor: (@controller) ->
    @progressBar = new Turbolinks.ProgressBar

  visitProposedToLocationWithAction: (location, action) ->
    @controller.startVisitToLocationWithAction(location, action)

  visitStarted: (visit) ->
    visit.issueRequest()
    visit.changeHistory()
    visit.loadCachedSnapshot()

  visitRequestStarted: (visit) ->
    @progressBar.setValue(0)
    if visit.hasCachedSnapshot() or visit.action isnt "restore"
      @showProgressBarAfterDelay()
    else
      @showProgressBar()

  visitRequestProgressed: (visit) ->
    @progressBar.setValue(visit.progress)

  visitRequestCompleted: (visit) ->
    visit.loadResponse()

  visitRequestFailedWithStatusCode: (visit, statusCode) ->
    switch statusCode
      when NETWORK_FAILURE, TIMEOUT_FAILURE
        @reload()
      else
        visit.loadResponse()

  visitRequestFinished: (visit) ->
    @hideProgressBar()

  visitCompleted: (visit) ->
    visit.followRedirect()

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
