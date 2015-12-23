class Browser.Session
  constructor: (@agent) ->
    @agent.delegate = this
    @navigationCallback = null

  navigateTo: (location, callback) ->
    @navigateWithCallback callback, =>
      @agent.navigateTo(location)

  clickSelector: (selector, callback) ->
    @navigateWithCallback callback, =>
      @agent.clickSelector(selector)

  # Agent delegate

  pageLoaded: (location) ->
    @navigatedToLocationWithAction(location, "load")

  pageLoadFailed: (location) ->
    @navigatedToLocationWithAction(location, "error")

  historyPushed: (location) ->
    @navigatedToLocationWithAction(location, "push")

  historyReplaced: (location) ->
    @navigatedToLocationWithAction(location, "replace")

  historyPopped: (location) ->
    @navigatedToLocationWithAction(location, "pop")

  # Private

  navigateWithCallback: (callback, performNavigation) ->
    if @navigating
      throw new Error "Navigation already in progress"
    else
      @navigating = true
      @navigationCallback = callback
      performNavigation()

  navigatedToLocationWithAction: (location, action) ->
    if @navigating and callback = @navigationCallback
      @navigationCallback = null
      defer =>
        @navigating = false
        callback(location, action)

  defer = (callback) ->
    requestAnimationFrame ->
      requestAnimationFrame(callback)
