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

  getRootLocation: ->
    root = @getSetting("root") ? "/"
    new Turbolinks.Location root

  getCacheControlValue: ->
    @getSetting("cache-control")

  hasAnchor: (anchor) ->
    @body.querySelector("##{anchor}")?

  isPreviewable: ->
    @getCacheControlValue() isnt "no-preview"

  # Private

  getSetting: (name) ->
    [..., element] = @head.querySelectorAll("meta[name='turbolinks-#{name}']")
    element?.getAttribute("content")
