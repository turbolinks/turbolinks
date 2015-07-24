class Turbolinks.Location
  @box: (value) ->
    if value instanceof this
      value
    else
      new this value

  constructor: (url = "") ->
    linkWithAnchor = document.createElement("a")
    linkWithAnchor.href = url.toString()
    @absoluteURL = linkWithAnchor.href

    if linkWithAnchor.hash.length < 2
      @requestURL = @absoluteURL
    else
      linkWithoutAnchor = linkWithAnchor.cloneNode()
      linkWithoutAnchor.hash = ""
      @requestURL = linkWithoutAnchor.href

  getOrigin: ->
    @absoluteURL.split("/", 3).join("/")

  isSameOrigin: ->
    @getOrigin() is (new @constructor).getOrigin()

  toCacheKey: ->
    @requestURL

  toJSON: ->
    @absoluteURL

  toString: ->
    @absoluteURL

  valueOf: ->
    @absoluteURL
