class Turbolinks.Location
  @wrap: (value) ->
    if value instanceof this
      value
    else
      new this value

  constructor: (url = "") ->
    link = document.createElement("a")
    link.href = url.toString()

    @absoluteURL = link.href
    @anchor = @absoluteURL.match(/#(.*)$/)?[1] ? null

    @requestURL = if @anchor?
      @absoluteURL.slice(0, -(@anchor.length + 1))
    else
      @absoluteURL

  getOrigin: ->
    @absoluteURL.split("/", 3).join("/")

  getPath: ->
    @requestURL.match(/\/\/[^/]*(\/[^?;]*)/)?[1] ? "/"

  getPathComponents: ->
    @getPath().split("/").slice(1)

  getLastPathComponent: ->
    @getPathComponents().slice(-1)[0]

  getExtension: ->
    @getLastPathComponent().match(/\.[^.]*$/)?[0] ? ""

  isHTML: ->
    @getExtension().match(/^(?:|\.(?:htm|html|xhtml))$/)

  isPrefixedBy: (location) ->
    prefixURL = getPrefixURL(location)
    @isEqualTo(location) or stringStartsWith(@absoluteURL, prefixURL)

  isEqualTo: (location) ->
    @absoluteURL is location?.absoluteURL

  toCacheKey: ->
    @requestURL

  toJSON: ->
    @absoluteURL

  toString: ->
    @absoluteURL

  valueOf: ->
    @absoluteURL

  # Private

  getPrefixURL = (location) ->
    addTrailingSlash(location.getOrigin() + location.getPath())

  addTrailingSlash = (url) ->
    if stringEndsWith(url, "/") then url else url + "/"

  stringStartsWith = (string, prefix) ->
    string.slice(0, prefix.length) is prefix

  stringEndsWith = (string, suffix) ->
    string.slice(-suffix.length) is suffix
