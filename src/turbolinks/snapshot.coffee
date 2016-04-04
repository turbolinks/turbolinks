class Turbolinks.Snapshot
  @wrap: (value) ->
    if value instanceof this
      value
    else
      @fromHTML(value)

  @fromHTML: (html) ->
    element = document.createElement("html")
    element.innerHTML = html
    @fromElement(element)

  @fromElement: (element) ->
    new this
      head: element.querySelector("head")
      body: element.querySelector("body")

  constructor: ({head, body}) ->
    @head = head ? document.createElement("head")
    @body = body ? document.createElement("body")

  clone: ->
    new Snapshot
      head: @head.cloneNode(true)
      body: @body.cloneNode(true)

  getRootLocation: ->
    root = @getSetting("root") ? "/"
    new Turbolinks.Location root

  getCacheControlValue: ->
    @getSetting("cache-control")

  hasAnchor: (anchor) ->
    try @body.querySelector("[id='#{anchor}']")?

  isPreviewable: ->
    @getCacheControlValue() isnt "no-preview"

  isCacheable: ->
    @getCacheControlValue() isnt "no-cache"

  # Private

  getSetting: (name) ->
    [..., element] = @head.querySelectorAll("meta[name='turbolinks-#{name}']")
    element?.getAttribute("content")
