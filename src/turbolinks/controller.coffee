#= require turbolinks/location
#= require turbolinks/browser_adapter
#= require turbolinks/history
#= require turbolinks/view
#= require turbolinks/cache
#= require turbolinks/http_request

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
    if @applicationAllowsVisitingLocation(location)
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
    @notifyApplicationAfterResponseLoad()
    @notifyApplicationAfterPageLoad()

  # Current request

  issueRequestForLocation: (location) ->
    @abortCurrentRequest()
    @request = new Turbolinks.HttpRequest @adapter, location
    @request.send()

  abortCurrentRequest: ->
    @request?.abort()

  # Page snapshots

  saveSnapshot: ->
    if @responseLoaded
      @notifyApplicationBeforeSnapshotSave()
      snapshot = @view.saveSnapshot()
      @cache.put(@location, snapshot)

  hasSnapshotForLocation: (location) ->
    @cache.has(location)

  restoreSnapshotByScrollingToSavedPosition: (scrollToSavedPosition) ->
    if snapshot = @cache.get(@location)
      @view.loadSnapshotByScrollingToSavedPosition(snapshot, scrollToSavedPosition)
      @notifyApplicationAfterSnapshotLoad()
      true

  # View delegate

  viewInvalidated: ->
    @adapter.pageInvalidated()

  # History delegate

  locationChangedByActor: (location, actor) ->
    @saveSnapshot()
    @responseLoaded = false
    @location = location
    @adapter.locationChangedByActor(location, actor)

  # Event handlers

  pageLoaded: =>
    @notifyApplicationAfterPageLoad()

  clickCaptured: =>
    removeEventListener("click", @clickBubbled, false)
    addEventListener("click", @clickBubbled, false)

  clickBubbled: (event) =>
    if @clickEventIsSignificant(event)
      if link = @getVisitableLinkForNode(event.target)
        if location = @getVisitableLocationForLink(link)
          if @applicationAllowsFollowingLinkToLocation(link, location)
            event.preventDefault()
            @visit(location)

  # Application events

  applicationAllowsFollowingLinkToLocation: (link, location) ->
    @dispatchEvent("turbolinks:click", target: link, data: { url: location.absoluteURL }, cancelable: true)

  applicationAllowsVisitingLocation: (location) ->
    @dispatchEvent("turbolinks:visit", data: { url: location.absoluteURL }, cancelable: true)

  notifyApplicationBeforeSnapshotSave: ->
    @dispatchEvent("turbolinks:snapshot-save")

  notifyApplicationAfterSnapshotLoad: ->
    @dispatchEvent("turbolinks:snapshot-load")

  notifyApplicationAfterResponseLoad: ->
    @dispatchEvent("turbolinks:response-load")

  notifyApplicationAfterPageLoad: ->
    @dispatchEvent("turbolinks:load")

  # Private

  dispatchEvent: ->
    event = Turbolinks.dispatch(arguments...)
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

  getVisitableLinkForNode: (node) ->
    if @nodeIsVisitable(node)
      Turbolinks.closest(node, "a[href]:not([target])")

  getVisitableLocationForLink: (link) ->
    location = new Turbolinks.Location link.href
    location if location.isSameOrigin()

  nodeIsVisitable: (node) ->
    if container = Turbolinks.closest(node, "[data-turbolinks]")
      container.getAttribute("data-turbolinks") isnt "false"
    else
      true

do ->
  Turbolinks.controller = controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller.start()
