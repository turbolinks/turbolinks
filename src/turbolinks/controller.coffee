#= require turbolinks/location
#= require turbolinks/browser_adapter
#= require turbolinks/history
#= require turbolinks/view
#= require turbolinks/cache

class Turbolinks.Controller
  constructor: ->
    @history = new Turbolinks.History this
    @view = new Turbolinks.View this
    @cache = new Turbolinks.Cache this
    @location = Turbolinks.Location.box(window.location)

  start: ->
    unless @started
      addEventListener("click", @clickCaptured, true)
      addEventListener("DOMContentLoaded", @pageLoaded, false)
      @history.start()
      @started = true

  stop: ->
    if @started
      removeEventListener("click", @clickCaptured, true)
      removeEventListener("DOMContentLoaded", @pageLoaded, false)
      @history.stop()
      @started = false

  visit: (location) ->
    location = Turbolinks.Location.box(location)
    @adapter.visitLocation(location)

  pushHistory: (location) ->
    location = Turbolinks.Location.box(location)
    @history.push(location)

  replaceHistory: (location) ->
    location = Turbolinks.Location.box(location)
    @history.replace(location)

  loadResponse: (response) ->
    @view.loadHTML(response)
    @notifyApplicationOfPageChange()

  # Page snapshots

  saveSnapshot: ->
    snapshot = @view.saveSnapshot()
    @cache.put(@location, snapshot)

  hasSnapshotForLocation: (location) ->
    location = Turbolinks.Location.box(location)
    @cache.get(location)?

  restoreSnapshotByScrollingToSavedPosition: (scrollToSavedPosition) ->
    if snapshot = @cache.get(@location)
      @view.loadSnapshotByScrollingToSavedPosition(snapshot, scrollToSavedPosition)
      @notifyApplicationOfSnapshotRestoration()
      true

  # History delegate

  locationChangedByActor: (location, actor) ->
    @saveSnapshot()
    @location = location
    @adapter.locationChangedByActor(location, actor)

  # Event handlers

  pageLoaded: =>
    @notifyApplicationOfPageChange()

  clickCaptured: =>
    removeEventListener("click", @clickBubbled, false)
    addEventListener("click", @clickBubbled, false)

  clickBubbled: (event) =>
    if not event.defaultPrevented and location = @getVisitableLocationForEvent(event)
      if @applicationAllowsChangingToLocation(location)
        event.preventDefault()
        @visit(location)

  # Events

  applicationAllowsChangingToLocation: (location) ->
    @triggerEvent("page:before-change", data: { url: location.toString() }, cancelable: true)

  notifyApplicationOfSnapshotRestoration: ->
    @triggerEvent("page:restore")

  notifyApplicationOfPageChange: ->
    @triggerEvent("page:change")
    @triggerEvent("page:update")

  # Private

  triggerEvent: (eventName, {cancelable, data} = {}) ->
    event = document.createEvent("Events")
    event.initEvent(eventName, true, cancelable is true)
    event.data = data
    document.dispatchEvent(event)
    not event.defaultPrevented

  getVisitableLocationForEvent: (event) ->
    if link = Turbolinks.closest(event.target, "a[href]")
      location = new Turbolinks.Location link.href
      location if location.isSameOrigin()


do ->
  Turbolinks.controller = controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller.start()
