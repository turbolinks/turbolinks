#= require ./location
#= require ./browser_adapter
#= require ./history
#= require ./view
#= require ./scroll_manager
#= require ./cache
#= require ./visit

class Turbolinks.Controller
  constructor: ->
    @history = new Turbolinks.History this
    @view = new Turbolinks.View this
    @scrollManager = new Turbolinks.ScrollManager this
    @restorationData = {}
    @clearCache()

  start: ->
    unless @started
      addEventListener("click", @clickCaptured, true)
      addEventListener("DOMContentLoaded", @pageLoaded, false)
      @scrollManager.start()
      @startHistory()
      @started = true
      @enabled = true

  disable: ->
    @enabled = false

  stop: ->
    if @started
      removeEventListener("click", @clickCaptured, true)
      removeEventListener("DOMContentLoaded", @pageLoaded, false)
      @scrollManager.stop()
      @stopHistory()
      @started = false

  clearCache: ->
    @cache = new Turbolinks.Cache 10

  visit: (location, options = {}) ->
    location = Turbolinks.Location.wrap(location)
    if @applicationAllowsVisitingLocation(location)
      if @locationIsVisitable(location)
        action = options.action ? "advance"
        @adapter.visitProposedToLocationWithAction(location, action)
      else
        window.location = location

  startVisitToLocationWithAction: (location, action, restorationIdentifier) ->
    if Turbolinks.supported
      restorationData = @getRestorationDataForIdentifier(restorationIdentifier)
      @startVisit(location, action, {restorationData})
    else
      window.location = location

  # History

  startHistory: ->
    @location = Turbolinks.Location.wrap(window.location)
    @restorationIdentifier = Turbolinks.uuid()
    @history.start()
    @history.replace(@location, @restorationIdentifier)

  stopHistory: ->
    @history.stop()

  pushHistoryWithLocationAndRestorationIdentifier: (location, @restorationIdentifier) ->
    @location = Turbolinks.Location.wrap(location)
    @history.push(@location, @restorationIdentifier)

  replaceHistoryWithLocationAndRestorationIdentifier: (location, @restorationIdentifier) ->
    @location = Turbolinks.Location.wrap(location)
    @history.replace(@location, @restorationIdentifier)

  # History delegate

  historyPoppedToLocationWithRestorationIdentifier: (location, @restorationIdentifier) ->
    if @enabled
      restorationData = @getRestorationDataForIdentifier(@restorationIdentifier)
      @startVisit(location, "restore", {@restorationIdentifier, restorationData, historyChanged: true})
      @location = Turbolinks.Location.wrap(location)
    else
      @adapter.pageInvalidated()

  # Snapshot cache

  getCachedSnapshotForLocation: (location) ->
    @cache.get(location)

  cacheSnapshot: ->
    @notifyApplicationBeforeCachingSnapshot()
    snapshot = @view.getSnapshot()
    @cache.put(@lastRenderedLocation, snapshot)

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

  # View

  render: (options, callback) ->
    @view.render(options, callback)

  viewInvalidated: ->
    @adapter.pageInvalidated()

  viewWillRender: (newBody) ->
    @notifyApplicationBeforeRender(newBody)

  viewRendered: ->
    @lastRenderedLocation = @currentVisit.location
    @notifyApplicationAfterRender()

  # Event handlers

  pageLoaded: =>
    @lastRenderedLocation = @location
    @notifyApplicationAfterPageLoad()

  clickCaptured: =>
    removeEventListener("click", @clickBubbled, false)
    addEventListener("click", @clickBubbled, false)

  clickBubbled: (event) =>
    if @enabled and @clickEventIsSignificant(event)
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

  notifyApplicationBeforeCachingSnapshot: ->
    @dispatchEvent("turbolinks:before-cache")

  notifyApplicationBeforeRender: (newBody) ->
    @dispatchEvent("turbolinks:before-render", data: {newBody})

  notifyApplicationAfterRender: ->
    @dispatchEvent("turbolinks:render")

  notifyApplicationAfterPageLoad: (timing = {}) ->
    @dispatchEvent("turbolinks:load", data: { url: @location.absoluteURL, timing })

  # Private

  startVisit: (location, action, properties) ->
    @currentVisit?.cancel()
    @currentVisit = @createVisit(location, action, properties)
    @currentVisit.start()

  createVisit: (location, action, {restorationIdentifier, restorationData, historyChanged} = {}) ->
    visit = new Turbolinks.Visit this, location, action
    visit.restorationIdentifier = restorationIdentifier ? Turbolinks.uuid()
    visit.restorationData = Turbolinks.copyObject(restorationData)
    visit.historyChanged = historyChanged
    visit.referrer = @location
    visit

  visitCompleted: (visit) ->
    @notifyApplicationAfterPageLoad(visit.getTimingMetrics())

  dispatchEvent: ->
    event = Turbolinks.dispatch(arguments...)
    not event.defaultPrevented

  clickEventIsSignificant: (event) ->
    not (
      event.defaultPrevented or
      event.target.isContentEditable or
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
    location if @locationIsVisitable(location)

  getActionForLink: (link) ->
    link.getAttribute("data-turbolinks-action") ? "advance"

  nodeIsVisitable: (node) ->
    if container = Turbolinks.closest(node, "[data-turbolinks]")
      container.getAttribute("data-turbolinks") isnt "false"
    else
      true

  locationIsVisitable: (location) ->
    location.isPrefixedBy(@getRootLocation()) and location.isHTML()

  getRootLocation: ->
    root = @getSetting("root") ? "/"
    new Turbolinks.Location root

  getSetting: (name) ->
    [..., element] = document.head.querySelectorAll("meta[name='turbolinks-#{name}']")
    element?.getAttribute("content")

  getCurrentRestorationData: ->
    @getRestorationDataForIdentifier(@restorationIdentifier)

  getRestorationDataForIdentifier: (identifier) ->
    @restorationData[identifier] ?= {}

do ->
  Turbolinks.controller = controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller.start()
