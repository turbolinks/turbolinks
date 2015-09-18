#= require ./location
#= require ./browser_adapter
#= require ./history
#= require ./view
#= require ./scroll_manager
#= require ./cache
#= require ./visit

class Turbolinks.Controller
  constructor: ->
    @location = Turbolinks.Location.box(window.location)
    @history = new Turbolinks.History this
    @view = new Turbolinks.View this
    @scrollManager = new Turbolinks.ScrollManager this
    @restorationData = {}
    @clearCache()

  start: ->
    unless @started
      addEventListener("click", @clickCaptured, true)
      addEventListener("DOMContentLoaded", @pageLoaded, false)
      @history.start()
      @scrollManager.start()
      @started = true

  stop: ->
    if @started
      removeEventListener("click", @clickCaptured, true)
      removeEventListener("DOMContentLoaded", @pageLoaded, false)
      @history.stop()
      @scrollManager.stop()
      @started = false

  clearCache: ->
    @cache = new Turbolinks.Cache 10

  visit: (location, options = {}) ->
    location = Turbolinks.Location.box(location)
    if @applicationAllowsVisitingLocation(location)
      action = options.action ? "advance"
      @adapter.visitProposedToLocationWithAction(location, action)

  pushHistoryWithLocationAndRestorationIdentifier: (location, restorationIdentifier) ->
    @location = Turbolinks.Location.box(location)
    @history.push(@location, restorationIdentifier)

  replaceHistoryWithLocationAndRestorationIdentifier: (location, restorationIdentifier) ->
    @location = Turbolinks.Location.box(location)
    @history.replace(@location, restorationIdentifier)

  loadResponse: (response) ->
    @view.loadSnapshotHTML(response)
    @notifyApplicationAfterResponseLoad()

  loadErrorResponse: (response) ->
    @view.loadDocumentHTML(response)
    @controller.stop()

  startVisitToLocationWithAction: (location, action) ->
    @startVisit(location, action)

  # Page snapshots

  hasSnapshotForLocation: (location) ->
    @cache.has(location)

  saveSnapshot: ->
    @notifyApplicationBeforeSnapshotSave()
    snapshot = @view.saveSnapshot()
    @cache.put(@lastRenderedLocation, snapshot)

  restoreSnapshotForLocation: (location) ->
    if snapshot = @cache.get(location)
      @view.loadSnapshot(snapshot)
      @notifyApplicationAfterSnapshotLoad()
      true
      
  # Scrolling

  scrollToAnchor: (anchor) ->
    if element = document.getElementById(anchor)
      @scrollToElement(element)
    else
      @scrollToPosition(x: 0, y: 0)
  
  scrollToElement: (element) ->
    @scrollManager.scrollToElement(element)
  
  scrollToPosition: (position) ->
    @scrollManager.scrollToPosition(position)
  
  # Scroll manager delegate

  scrollPositionChanged: (scrollPosition) ->
    restorationData = @getCurrentRestorationData()
    restorationData.scrollPosition = scrollPosition

  # View delegate

  viewInvalidated: ->
    @adapter.pageInvalidated()

  viewRendered: ->
    @lastRenderedLocation = @currentVisit.location

  # History delegate

  historyPoppedToLocationWithRestorationIdentifier: (location, restorationIdentifier) ->
    restorationData = @getRestorationDataForIdentifier(restorationIdentifier)
    @startVisit(location, "restore", {restorationIdentifier, restorationData, historyChanged: true})
    @location = location

  # Event handlers

  pageLoaded: =>
    @lastRenderedLocation = @location
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
            action = @getActionForLink(link)
            @visit(location, {action})

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

  startVisit: (location, action, properties) ->
    @currentVisit?.cancel()
    @currentVisit = @createVisit(location, action, properties)
    @currentVisit.start()

  createVisit: (location, action, {restorationIdentifier, restorationData, historyChanged} = {}) ->
    visit = new Turbolinks.Visit this, location, action
    visit.restorationIdentifier = restorationIdentifier ? Turbolinks.uuid()
    visit.restorationData = restorationData
    visit.historyChanged = historyChanged
    visit.then(@visitFinished)
    visit

  visitFinished: =>
    @notifyApplicationAfterPageLoad()

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

  getActionForLink: (link) ->
    link.getAttribute("data-turbolinks-action") ? "advance"

  nodeIsVisitable: (node) ->
    if container = Turbolinks.closest(node, "[data-turbolinks]")
      container.getAttribute("data-turbolinks") isnt "false"
    else
      true

  getCurrentRestorationData: ->
    @getRestorationDataForIdentifier(@history.restorationIdentifier)

  getRestorationDataForIdentifier: (identifier) ->
    @restorationData[identifier] ?= {}
  
do ->
  Turbolinks.controller = controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller.start()
