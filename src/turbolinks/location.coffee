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

    anchorLength = linkWithAnchor.hash.length
    if anchorLength < 2
      @requestURL = @absoluteURL
    else
      @requestURL = @absoluteURL.slice(0, -anchorLength)
      @anchor = linkWithAnchor.hash.slice(1)

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
