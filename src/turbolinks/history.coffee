class Turbolinks.History
  constructor: (@delegate) ->

  start: ->
    unless @started
      addEventListener("popstate", @onPopState, false)
      addEventListener("load", @onPageLoad, false)
      @started = true

  stop: ->
    if @started
      removeEventListener("popstate", @onPopState, false)
      removeEventListener("load", @onPageLoad, false)
      @started = false

  push: (location, restorationIdentifier) ->
    location = Turbolinks.Location.wrap(location)
    @update("push", location, restorationIdentifier)

  replace: (location, restorationIdentifier) ->
    location = Turbolinks.Location.wrap(location)
    @update("replace", location, restorationIdentifier)

  # Event handlers

  # Chrome < 34 and Safari < 10 dispatch an initial popstate event on page load.
  # Ignore it by setting the pageLoaded after the page load is done (hence defer).
  # Details: https://developer.mozilla.org/en/docs/Web/API/WindowEventHandlers/onpopstate

  onPageLoad: (event) =>
    Turbolinks.defer =>
      @pageLoaded = true

  onPopState: (event) =>
    if @shouldHandlePopState()
      if turbolinks = event.state?.turbolinks
        location = Turbolinks.Location.wrap(window.location)
        restorationIdentifier = turbolinks.restorationIdentifier
        @delegate.historyPoppedToLocationWithRestorationIdentifier(location, restorationIdentifier)

  # Private

  shouldHandlePopState: ->
    @pageIsLoaded()

  pageIsLoaded: ->
    @pageLoaded

  update: (method, location, restorationIdentifier) ->
    state = turbolinks: {restorationIdentifier}
    history[method + "State"](state, null, location)
