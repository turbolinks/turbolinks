#= require turbolinks/location
#= require turbolinks/browser_adapter
#= require turbolinks/history
#= require turbolinks/view
#= require turbolinks/cache

class Turbolinks.Controller
  constructor: ->
    @history = new Turbolinks.History this
    @view = new Turbolinks.View this
    @cache = new Turbolinks.Cache 10
    @location = Turbolinks.Location.box(window.location)
    @responseLoaded = true

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
    @responseLoaded = true
    @notifyApplicationOfPageChange()

  # Current request

  issueRequestForLocation: (location) ->
    location = Turbolinks.Location.box(location)
    @abortCurrentRequest()
    @xhr = new XMLHttpRequest
    @xhr.open("GET", location.requestURL, true)
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml, application/xml")
    @xhr.onloadend = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.onabort = @requestAborted
    @xhr.send()

  abortCurrentRequest: ->
    @xhr?.abort()

  requestLoaded: =>
    if 200 <= @xhr.status < 300
      @adapter.requestCompletedWithResponse(@xhr.responseText)
    else
      @adapter.requestFailedWithStatusCode(@xhr.status, @xhr.responseText)
    @xhr = null

  requestFailed: =>
    @adapter.requestFailedWithStatusCode(null)
    @xhr = null

  requestAborted: =>
    @xhr = null

  # Page snapshots

  saveSnapshot: ->
    if @responseLoaded
      snapshot = @view.saveSnapshot()
      @cache.put(@location, snapshot)

  hasSnapshotForLocation: (location) ->
    @cache.has(location)

  restoreSnapshotByScrollingToSavedPosition: (scrollToSavedPosition) ->
    if snapshot = @cache.get(@location)
      @view.loadSnapshotByScrollingToSavedPosition(snapshot, scrollToSavedPosition)
      @notifyApplicationOfSnapshotRestoration()
      true

  # History delegate

  locationChangedByActor: (location, actor) ->
    @saveSnapshot()
    @responseLoaded = false
    @location = location
    @adapter.locationChangedByActor(location, actor)

  # Event handlers

  pageLoaded: =>
    @notifyApplicationOfPageChange()

  clickCaptured: =>
    removeEventListener("click", @clickBubbled, false)
    addEventListener("click", @clickBubbled, false)

  clickBubbled: (event) =>
    if @clickEventIsSignificant(event) and location = @getVisitableLocationForNode(event.target)
      if @applicationAllowsChangingToLocation(location)
        event.preventDefault()
        @visit(location)

  # Events

  applicationAllowsChangingToLocation: (location) ->
    @triggerEvent("page:before-change", data: { url: location.absoluteURL }, cancelable: true)

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

  clickEventIsSignificant: (event) ->
    not (
      event.defaultPrevented or
      event.which > 1 or
      event.altKey or
      event.ctrlKey or
      event.metaKey or
      event.shiftKey
    )

  getVisitableLocationForNode: (node) ->
    if link = Turbolinks.closest(node, "a[href]")
      location = new Turbolinks.Location link.href
      location if location.isSameOrigin()


do ->
  Turbolinks.controller = controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller.start()
