class Turbolinks.History
  constructor: (@delegate) ->

  start: ->
    unless @started
      @update("replace", null)
      addEventListener("popstate", @onPopState, false)
      @started = true

  stop: ->
    if @started
      removeEventListener("popstate", @onPopState, false)
      @started = false

  push: (location) ->
    location = Turbolinks.Location.box(location)
    @update("push", location)

  replace: (location) ->
    location = Turbolinks.Location.box(location)
    @update("replace", location)

  # Event handlers

  onPopState: (event) =>
    if turbolinks = event.state?.turbolinks
      location = Turbolinks.Location.box(window.location)
      @restorationIdentifier = turbolinks.restorationIdentifier
      @delegate.historyPoppedToLocationWithRestorationIdentifier(location, @restorationIdentifier)

  # Private

  update: (method, location) ->
    {@restorationIdentifier} = state = createState()
    history[method + "State"](state, null, location)

  createState = ->
    time = new Date().getTime()
    entropy = Math.floor(Math.random() * 1000, 10) + 1
    turbolinks: restorationIdentifier: "#{time}.#{entropy}"
