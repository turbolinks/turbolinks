class Turbolinks.ProgressBar
  DELAY = 300

  @defaultCSS: """
    .turbolinks-progress-bar {
      position: fixed;
      display: block;
      top: 0;
      left: 0;
      height: 3px;
      background: #0076ff;
      z-index: 9999;
      transition: width #{DELAY}ms ease-out, opacity #{DELAY / 2}ms ease-in;
      transform: translate3d(0, 0, 0);
    }
  """

  constructor: ->
    @stylesheetElement = @createStylesheetElement()
    @progressElement = @createProgressElement()

  show: ->
    unless @visible
      @visible = true
      @installStylesheetElement()
      @installProgressElement()
      @startTrickling()

  hide: ->
    if @visible and not @hiding
      @hiding = true
      @fadeProgressElement =>
        @uninstallProgressElement()
        @stopTrickling()
        @visible = false
        @hiding = false

  setValue: (@value) ->
    @progressElement.style.width = "#{10 + (@value * 90)}%"

  # Private

  installStylesheetElement: ->
    document.head.insertBefore(@stylesheetElement, document.head.firstChild)

  installProgressElement: ->
    @progressElement.style.width = 0
    @progressElement.style.opacity = 1
    document.documentElement.insertBefore(@progressElement, document.body)

  fadeProgressElement: (callback) ->
    @progressElement.style.opacity = 0
    setTimeout(callback, DELAY * 1.5)

  uninstallProgressElement: ->
    document.documentElement.removeChild(@progressElement)

  startTrickling: ->
    @trickleInterval ?= setInterval(@trickle, DELAY)

  stopTrickling: ->
    clearInterval(@trickleInterval)
    @trickleInterval = null

  trickle: =>
    @setValue(@value + Math.random() / 100)

  createStylesheetElement: ->
    element = document.createElement("style")
    element.type = "text/css"
    element.textContent = @constructor.defaultCSS
    element

  createProgressElement: ->
    element = document.createElement("div")
    element.classList.add("turbolinks-progress-bar")
    element
