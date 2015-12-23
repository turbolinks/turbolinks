class Browser.Agent
  @create: ->
    element = document.createElement("div")
    element.innerHTML = JST["browser/browser"]()
    new this element.firstChild

  constructor: (@element) ->
    @configureContentFrame()
    @configureNavigationButtons()

  navigateTo: (location) ->
    @contentFrame.src = location
    @setState("loading")

  querySelector: (selector) ->
    @getContentDocument()?.querySelector(selector)

  clickSelector: (selector) ->
    if element = @querySelector(selector)
      trigger(element, "click")

  goBack: ->
    @getHistory()?.back()

  goForward: ->
    @getHistory()?.forward()

  # Browser state

  configureTimer: ->
    @timer ?= setInterval =>
      if @isAttachedToDocument()
        @updateTitle()
      else
        clearInterval(@timer)
        @timer = null
    , 50

  configureContentFrame: ->
    @contentFrame = @getBrowserElement("content-frame")
    @contentFrame.onload = @contentFrameLoadFinished
    @contentFrame.onerror = @contentFrameLoadFailed

  configureNavigationButtons: ->
    backButton = @getBrowserElement("navigation-button-back")
    backButton.onclick = @navigationBackButtonClicked
    forwardButton = @getBrowserElement("navigation-button-forward")
    forwardButton.onclick = @navigationForwardButtonClicked

  # Frame lifecycle

  contentFrameLoadFinished: =>
    try @configureContentWindow()
    @configureTimer()
    @setState("loaded")
    @updateLocation()
    @delegate?.pageLoaded?(@location)

  contentFrameLoadFailed: =>
    @setState("loaded")
    @updateLocation()
    @delegate?.pageLoadFailed?(@location)

  contentFrameHistoryPushed: ->
    @updateLocation()
    @delegate?.historyPushed?(@location)

  contentFrameHistoryReplaced: ->
    @updateLocation()
    @delegate?.historyReplaced?(@location)

  contentFrameHistoryPopped: ->
    @updateLocation()
    @delegate?.historyPopped?(@location)

  contentFrameWillUnload: ->
    @setState("loading")

  # Window event listeners

  configureContentWindow: ->
    {contentWindow} = @contentFrame
    @configureContentWindowHistory()
    contentWindow.addEventListener("beforeunload", @beforeUnload, true)
    defer => contentWindow.addEventListener?("popstate", @afterPopState, false)

  beforeUnload: =>
    @contentFrameWillUnload()
    return

  afterPopState: =>
    @contentFrameHistoryPopped()

  # History instrumentation

  configureContentWindowHistory: ->
    {prototype} = @getHistory().constructor
    instrument(prototype, "pushState", @afterPushState)
    instrument(prototype, "replaceState", @afterReplaceState)

  afterPushState: =>
    @contentFrameHistoryPushed()

  afterReplaceState: =>
    @contentFrameHistoryReplaced()

  # Navigation buttons

  navigationBackButtonClicked: =>
    @goBack()

  navigationForwardButtonClicked: =>
    @goForward()

  # Private

  getBrowserElement: (className) ->
    @element.querySelector(".browser-#{className}")

  isAttachedToDocument: ->
    {documentElement} = @element.ownerDocument
    position = documentElement.compareDocumentPosition(@element)
    not (position & Node.DOCUMENT_POSITION_DISCONNECTED)

  getContentWindow: ->
    @contentFrame?.contentWindow

  getContentDocument: ->
    @getContentWindow()?.document

  getHistory: ->
    @getContentWindow()?.history

  setState: (state) ->
    if state isnt @state
      @element.dataset.state = @state = state
      @delegate?.stateChanged?(@state)

  setLocation: (location) ->
    @location = location.toString()
    @getBrowserElement("navigation-url").value = @location

  updateLocation: ->
    @setLocation(@getContentWindow().location)

  setTitle: (@title) ->
    @getBrowserElement("titlebar-title").textContent = @title

  updateTitle: ->
    @setTitle(@getContentDocument()?.title ? "")

  instrument = (object, methodName, replacement) ->
    original = object[methodName]
    object[methodName] = ->
      result = original.apply(this, arguments)
      replacement()
      result

  trigger = (element, eventName) ->
    event = element.ownerDocument.createEvent("Events")
    event.initEvent(eventName, true, true)
    element.dispatchEvent(event)

  defer = (callback) ->
    setTimeout(callback, 1)
