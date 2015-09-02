class Turbolinks.History
  constructor: (@delegate) ->
    @state = { turbolinks: true }

  start: ->
    unless @started
      addEventListener("popstate", @onPopState, false)
      @started = true

  stop: ->
    if @started
      removeEventListener("popstate", @onPopState, false)
      @started = false

  push: (location) ->
    location = Turbolinks.Location.box(location)

    unless @initialized
      @update("replace", null)
      @initialized = true

    @update("push", location)

  replace: (location) ->
    location = Turbolinks.Location.box(location)
    @update("replace", location)

  # Event handlers

  onPopState: (event) =>
    if event.state?.turbolinks
      location = Turbolinks.Location.box(window.location)
      @delegate.historyPoppedToLocation(location)

  # Private

  update: (method, location) ->
    history[method + "State"](@state, null, location)
