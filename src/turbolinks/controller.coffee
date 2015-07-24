#= require turbolinks/browser_adapter
#= require turbolinks/history
#= require turbolinks/view
#= require turbolinks/cache

class Turbolinks.Controller
  constructor: ->
    @history = new Turbolinks.History this
    @view = new Turbolinks.View this
    @cache = new Turbolinks.Cache this
    @location = window.location.toString()

  start: ->
    unless @started
      addEventListener("popstate", @historyPopped, false)
      addEventListener("click", @clickCaptured, true)
      @started = true

  stop: ->
    if @started
      removeEventListener("popstate", @historyPopped, false)
      removeEventListener("click", @clickCaptured, true)
      @started = false

  visit: (location) ->
    @adapter.visitLocation(location)

  pushHistory: (location) ->
    @history.push(location)

  replaceHistory: (location) ->
    @history.replace(location)

  loadResponse: (response) ->
    @view.loadHTML(response)

  # Page snapshots

  saveSnapshot: ->
    snapshot = @view.saveSnapshot()
    @cache.put(@location, snapshot)

  hasSnapshotForLocation: (location) ->
    @cache.get(location)?

  restoreSnapshotByScrollingToSavedPosition: (scrollToSavedPosition) ->
    if snapshot = @cache.get(@location)
      @view.loadSnapshotByScrollingToSavedPosition(snapshot, scrollToSavedPosition)
      true

  # History delegate

  historyChanged: (location) ->
    @locationChangedByActor(location, "application")

  # Event handlers

  historyPopped: (event) =>
    if event.state?.turbolinks
      @locationChangedByActor(window.location.toString(), "history")

  clickCaptured: =>
    removeEventListener("click", @clickBubbled, false)
    addEventListener("click", @clickBubbled, false)

  clickBubbled: (event) =>
    if not event.defaultPrevented and location = @getVisitableLocationForEvent(event)
      event.preventDefault()
      @visit(location)

  # Private

  locationChangedByActor: (location, actor) ->
    @saveSnapshot()
    @location = location
    @adapter.locationChangedByActor(location, actor)

  getVisitableLocationForEvent: (event) ->
    link = Turbolinks.closest(event.target, "a")
    link.href if isSameOrigin(link?.href)

  isSameOrigin = (url) ->
    url?


do ->
  Turbolinks.controller = controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller.start()
