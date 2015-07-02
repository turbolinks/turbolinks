#= require turbolinks/browser_adapter
#= require turbolinks/history
#= require turbolinks/view

class Turbolinks.Controller
  constructor: (adapterConstructor) ->
    @adapter = new adapterConstructor this
    @history = new Turbolinks.History this
    @view = new Turbolinks.View this

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

  visit: (url) ->
    @adapter.visitLocation(url)

  loadResponse: (response) ->
    @view.loadHTML(response)

  # Adapter delegate

  adapterLoadedResponse: (response) ->
    @loadResponse(response)

  getHistoryForAdapter: (adapter) ->
    @history

  # History delegate

  historyChanged: (url) ->
    @locationChanged(url)

  # Event handlers

  historyPopped: (event) =>
    if event.state?.turbolinks
      @locationChanged(location.toString())

  clickCaptured: =>
    removeEventListener("click", @clickBubbled, false)
    addEventListener("click", @clickBubbled, false)

  clickBubbled: (event) =>
    if not event.defaultPrevented and url = @getVisitableURLForEvent(event)
      event.preventDefault()
      @visit(url)

  # Private

  locationChanged: (url) ->
    @adapter.locationChanged(url)

  getVisitableURLForEvent: (event) ->
    link = Turbolinks.closest(event.target, "a")
    link.href if isSameOrigin(link?.href)

  isSameOrigin = (url) ->
    url?


do ->
  Turbolinks.controller = new Turbolinks.Controller(Turbolinks.BrowserAdapter)
  Turbolinks.controller.start()
