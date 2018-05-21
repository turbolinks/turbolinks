#= require ./head_details

class Turbolinks.Snapshot
  @wrap: (value) ->
    if value instanceof this
      value
    else if typeof value == "string"
      @fromHTMLString(value)
    else
      @fromHTMLElement(value)

  @fromHTMLString: (html) ->
    htmlElement = document.createElement("html")
    htmlElement.innerHTML = html
    @fromHTMLElement(htmlElement)

  @fromHTMLElement: (htmlElement) ->
    headElement = htmlElement.querySelector("head")
    bodyElement = htmlElement.querySelector("body") ? document.createElement("body")
    headDetails = Turbolinks.HeadDetails.fromHeadElement(headElement)
    new this headDetails, bodyElement

  constructor: (@headDetails, @body) ->

  clone: ->
    new @constructor @headDetails, @body.cloneNode(true)

  getRootLocation: ->
    root = @getSetting("root") ? "/"
    new Turbolinks.Location root

  getCacheControlValue: ->
    @getSetting("cache-control")

  getElementForAnchor: (anchor) ->
    try @body.querySelector("[id='#{anchor}'], a[name='#{anchor}']")

  hasAnchor: (anchor) ->
    @getElementForAnchor(anchor)?

  isPreviewable: ->
    @getCacheControlValue() isnt "no-preview"

  isCacheable: ->
    @getCacheControlValue() isnt "no-cache"

  isVisitable: ->
    @getSetting("visit-control") isnt "reload"

  # Private

  getSetting: (name) ->
    @headDetails.getMetaValue("turbolinks-#{name}")
